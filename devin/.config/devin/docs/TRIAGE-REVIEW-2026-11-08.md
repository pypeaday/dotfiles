# Alert-triage review — verdicts.jsonl (4170 rows, 2026-10-15 → 2026-11-08)

**Mode note:** `mode=shadow` covers only 136 rows (10-15 → 10-19 13:14). The service
flipped to `mode=enforce` at 10-19 14:52 — the remaining 4034 rows are real
enforcement data, so this is effectively a 3-week enforce audit.

## 1. Counts by verdict × tier

| verdict  | t1 (rules) | t2 (ollama) |
|----------|-----------:|------------:|
| notify   | 2544       | 236         |
| digest   | 995        | 1           |
| suppress | 394        | 0           |

t2 handled 237 alerts (5.7%) — everything else died or bypassed at t1. t2's
non-notify rate is 0.4%: gemma3:4b is effectively a notify rubber-stamp.

## 2. t2 verdicts that look wrong

**Dangerous direction — digested/suppressed something real: none.** Zero t2
suppress in the whole log; the only non-notify t2 verdict is a digest on
`TRIAGE-ENFORCE-TEST` ("Smoke test, likely benign. No recent issues.") — a
synthetic rule, correct call. No real outage was ever digested or suppressed.

**Over-notify direction — chronic conditions the LLM kept paging instead of
digesting (wrong for a triage layer, though "safe"):**

- `Sanoid snapshots monitor` — 73 t2 notifies over 11-03→11-08 (~15/day):
  "ZFS snapshots stale - backups at risk, immediate action needed." A standing
  condition paged daily — the textbook digest case per the skill notes.
- `Disk temperature high` — 65 t2 notifies: "Persistent high temp, investigate
  airflow/enclosure." The model itself says *persistent* and still notifies.
- `Host swap exhaustion (>85% used)` — 37 t2 notifies over 10-19→10-25:
  "Swap >99% - Critical, immediate investigation needed." Chronic aurora swap.
- `DH — Site probe STALE` — 37 t2 notifies: "Persistent stale probe - potential
  outage." Defensible call (could mask a real outage) but a standing
  monitoring-gap alert — belongs in a refire/digest rule, plus 3 notifies ~10s
  apart at 11-05 01:15 escaped dedupe.
- `Sanoid health monitor` — 19 t2 notifies: "Persistent ZFS errors - immediate
  investigation needed." Chronic pool errors.

## 3. Fail-open

**70 rows (1.7%)**, all `verdict=notify`, `reason="fail-open (no LLM verdict)"` —
correct behavior (page + pass through). Causes:

- 2 rows `ms=0` during bring-up on 10-15 (TEST Triage, TRIAGE-TEST — LLM not yet
  wired / instant connection failure).
- 68 rows `ms≈30000` = **ollama timeouts at the 30s limit**, spread ~2/day with a
  cluster on 11-04/11-05. t2 latency p50=18.4s p95=29.1s max=29.9s — inference
  sits just under the timeout, so any host contention tips it into fail-open.

## 4. t1 issues worth noting

- **Resolved-echo noise:** 1656 notifies are "resolved notice"; 589 of them are
  `Sanoid warning` resolves for firings that were *digested* — pages for alerts
  nobody was paged about. Resolved echoes should only send if the firing
  actually notified.
- Digest list catches `Sanoid warning` firings (859) but not the other chronic
  rules above, so they fall through to t2 and page.

## 5. Recommendation: needs-tuning (enforce is not dangerous, just noisy)

t2 has never under-notified — flipping enforce cannot eat a real alert with the
current model behavior. The risk is page volume, not missed pages. Tune before
calling it done:

1. **rules.json digest list** — add the chronic rules: `Sanoid snapshots
   monitor`, `Sanoid health monitor`, `Host swap exhaustion`, `Disk temperature
   high` (beyond first-firing refire), `DH — Site probe STALE` refire. Or better:
   fix the underlying conditions (stale snapshots, aurora swap, ZFS errors,
   site-monitor probe gaps).
2. **Resolve-echo gating** — don't page a resolved notice when its firing was
   digested/suppressed (-589 noise pages in this window).
3. **LLM latency** — p50 18s/p95 29s against a 30s timeout yields ~2 fail-opens
   a day. Reduce ollama contention, raise the timeout, or accept the
   unfiltered pass-throughs (they still notify, so impact is only annotation
   delay).
4. **Prompt** (optional) — instruct that warnings self-described as
   persistent/chronic across recent history should `digest`, so t2 actually
   absorbs standing alerts instead of rubber-stamping them.

After 1-2, enforce mode does its job: criticals bypass, chronic noise digests,
real anomalies still page.
