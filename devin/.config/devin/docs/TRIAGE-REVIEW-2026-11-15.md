# Alert Triage — Shadow-Mode Review

Window: 2026-10-15 → 2026-11-15 (~31 days) · 5,546 verdicts · mode=shadow

## 1. Counts by verdict × tier

| tier | notify | digest | suppress | total |
|------|--------|--------|----------|-------|
| t1 (rules) | 3,269 | 1,407 | 568 | 5,244 |
| t2 (gemma3:4b) | 301 | 1 | 0 | 302 |
| **total** | **3,570** | **1,408** | **568** | **5,546** |

t1 digest breakdown: `Sanoid warning` digest-list 1,154 + 85 resolve echoes;
refire rules: `Disk temperature high` 112, `Host swap thrashing` 56.
All 568 t1 suppresses are dedupe within cooldown — no suppress-list kills.

Loudest rules: `Sanoid CRITICAL` 1,492 (684 critical-bypass pages + 604
resolved notices + 204 deduped), `Sanoid warning` 1,930 (64% digested),
`Edge silent` 316, `Disk temperature high` 438, `DH — Site DOWN` 231.

## 2. t2 verdicts that look wrong

**Dangerous direction: zero.** t2 never suppressed anything and digested
only `TRIAGE-ENFORCE-TEST` ("Smoke test, likely benign. No recent issues.") —
correct on a synthetic.

**Soft-wrong: ~245 refire over-notifies.** 280 of 302 t2 calls were refires
of just 22 fingerprints. The model re-pages standing conditions every dedupe
cooldown instead of digesting — the exact job it exists for:

- `Sanoid snapshots monitor` ×126 notify, 2 fingerprints (88+38 refires):
  "ZFS snapshots stale - backups at risk", "ZFS snapshots critical, backups
  at risk.", "Critical ZFS snapshot issue - backups at risk."
  Sibling rule `Sanoid warning` is already t1 digest-listed — these should
  digest too.
- `Sanoid health monitor` ×29 notify: "Persistent ZFS errors - immediate
  investigation needed." — "persistent" = standing, not a fresh page.
- `Disk temperature high` ×65 notify on 2 fingerprints: "Persistent high
  temp, investigate airflow/enclosure" — reason admits refire, verdict still
  notify. t1 already digests refires of this rule; t2 un-does it for new
  fingerprints (different disks).
- `DH — Site probe STALE` ×37 notify across ~10 site fingerprints:
  "Persistent stale probe - potential outage." First page per site is right;
  ~27 are refires that should digest.
- `Host swap exhaustion` ×37 notify: "Swap >99% - Critical, immediate
  investigation needed." — defensible; swap >99% is genuinely actionable.

## 3. Fail-open: 149 total (33% of all t2 attempts)

- **147 × ~30s LLM timeout** — ms values cluster 30,002–30,037, i.e. the
  client timeout is ~30s and ollama regularly blows through it.
- **2 × connection failure** (ms=0) — early window, synthetic test alerts.
- Shape: rare in October (≤5/day), chronic since ~Nov 5 (9–15/day); ~120 of
  149 in the last 11 days. Concentrated on `Sanoid snapshots monitor` (65)
  and `Sanoid health monitor` (65) because they carry the volume.
- Related: 293/302 *successful* t2 calls also exceeded the 10s spec —
  avg 21.3s, max ~30s. Fail-open itself worked correctly (all 149 notified).

## 4. Recommendation: needs-tuning before MODE=enforce

Enforcing today is *low-danger* (t2 has never hidden a real alert) but
*near-zero value* — the LLM rubber-stamps `notify` and adds up to ~30s of
latency per alert while failing a third of the time. Fix first:

1. **rules.json digest list**: add `Sanoid snapshots monitor` and
   `Sanoid health monitor` (same standing family as digest-listed
   `Sanoid warning`) — removes ~51% of t2 traffic and 130/149 fail-opens.
2. **Critical bypass**: `Sanoid CRITICAL` is severity=critical and paged
   684× for a standing unprotected-datasets condition. Demote to warning or
   digest-list it — it's the single largest noise source.
3. **Refire coverage**: extend t1 refire→digest to `DH — Site probe STALE`
   and all disk-temp fingerprints, not just the first seen.
4. **Prompt**: add "a refire / persistent instance of the same condition
   digests; only novel or escalating alerts notify" — the model currently
   writes "Persistent …" in the reason while answering notify.
5. **Ollama host**: gemma3:4b averaging 21s/call with a ~30s timeout is why
   fail-open is chronic. Faster host/model or a smaller quant before
   enforce; also decide whether 10s or 30s is the real timeout and align
   config with the spec.

After 1–5, re-shadow ~1 week. Enforce is justified once t2 demonstrably
digests standing noise without touching a real outage — it hasn't been
asked to yet.

Next: flip nothing yet — update rules.json + prompt, fix ollama latency,
re-run this review on a fresh week of verdicts.
