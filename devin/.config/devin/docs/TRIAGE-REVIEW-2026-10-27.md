# Alert-triage verdict review — 2026-10-27

Source: `verdicts.jsonl` — 1,431 verdicts spanning **2026-10-15 → 2026-10-27**.

**Note:** the log is not pure shadow. `mode=enforce` begins 10-19 14:52 (marker: `TRIAGE-ENFORCE-TEST`); 1,295 rows are enforce, 136 shadow. These verdicts were live — digest/suppress calls actually ate pages.

## 1. Counts by verdict × tier

| tier | notify | digest | suppress |
|------|--------|--------|----------|
| t1 (rules) | 890 | 290 | 108 |
| t2 (gemma3:4b) | 142 | 1 | 0 |

t1 notify breaks down as: 561 resolved echoes, 313 critical-bypass, 16 fail-open. t1 digest is 286× `Sanoid warning` (digest list) + 4× refire rule. t1 suppress is all dedupe cooldowns.

## 2. t2 verdicts that look WRONG

The LLM never suppressed and digested exactly once. Its failure mode is **over-notify on standing conditions** — safe direction, but it means t2 filters ~0 noise:

- **`DH — Site probe STALE` → notify ×37** — "Persistent stale probe - potential outage." A stale probe is a monitoring gap, not a site outage; firing repeatedly for 8 days it should digest. Wrong framing, inflated urgency.
- **`Disk temperature high` → notify ×65** — "Persistent high temp, immediate investigation needed." Refires ~2×/day for 11 straight days = chronic thermal condition. After the first page this is noise; reason text even says "persistent" yet still escalates.
- **`Host swap exhaustion (>85% used)` → notify ×37** — "Swap >99% - Critical, immediate investigation needed." Swap pinned ≥98% for a week is chronic, not acute; warning severity, yet reason repeatedly calls it "critical."
- **`TRIAGE-LLM-TEST` → notify** — "Pool nearing capacity, requires immediate review." A synthetic test alert treated as real (rule name says TEST).
- Sole digest, `TRIAGE-ENFORCE-TEST` ("Smoke test, likely benign"), was correct.

Nothing was dangerously suppressed — the risky direction stayed clean.

## 3. Fail-open

**16 rows** (`fail-open (no LLM verdict)`, all warning severity, notified): the two initial pipeline tests on 10-15, then intermittent `DH — Site probe STALE`, `Host swap exhaustion`, `Disk temperature high` through 10-25 — ollama slow/unreachable moments. Fail-open behaved correctly.

Related: t2 latency p50 ≈ **15.4s**, max 28.9s; 135/143 calls exceed the documented 10s timeout — the deployed timeout is clearly ~30s, and every non-critical alert carries ~15s of added page delay.

## 4. Bottom line

The LLM tier is **safe but inert** — it never ate a real alert, and never filtered one either. Actual noise reduction comes entirely from t1 (dedupe + `Sanoid warning` digest list). Page volume is dominated by t1 policy, not the model:

- `Sanoid CRITICAL` fired 177× in 12 days → 177 critical-bypass pages + 177 resolved-echo pages. A "critical" firing ~15×/day is a broken rule, not a triage success.
- Resolved echoes = 561 of 890 t1 notifies (63%) — every flap costs a second page.
- Dedupe already suppressed 12 `DH — Site DOWN` refires; that part works.

**Recommendation: needs-tuning before enforce can be called healthy.** Enforce mode is already on and nothing actionable was lost, so no rollback needed — but:

1. Fix `Sanoid CRITICAL` at the source (threshold/schedule) or drop it from the critical-bypass list.
2. Gate resolved echoes — suppress or batch them for non-critical rules.
3. Move the three standing warnings (`Disk temperature high`, `Host swap exhaustion`, `DH — Site probe STALE`) onto the rules.json digest list, or add a t1 "refired >N times in 24h → digest" rule — don't rely on the LLM for chronic conditions.
4. Prompt fix: tell the model that warning-severity rules firing persistently over days should digest, not escalate; and that `*TEST*` rules are synthetic.
5. Reconcile the documented 10s LLM timeout with the observed ~30s ceiling.
