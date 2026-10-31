# Triage Review — 2026-10-25 (manual; scheduled run hit permission wall)

Window: 10-15 → 10-25 · 1,123 verdicts · 114 t2 (ollama gemma3:4b) calls
Mode: shadow (all alerts still notify; verdicts advisory)

## Counts by verdict + tier

| rule | t1 notify | t1 digest | t1 suppress | t2 |
|---|---|---|---|---|
| Sanoid CRITICAL | 258 | — | 2 | — |
| Sanoid warning | 130 | 233 | — | — |
| DH — Site DOWN | 120 | — | 12 | — |
| Disk temperature high | 99 | — | 53 | 47 notify |
| Host swap exhaustion | 20 | — | 10 | 33 notify |
| DH — Site probe STALE | 6 | — | — | 31 notify |
| Edge silent (Traefik) | 28 | — | 4 | — |
| Host memory pressure | 23 | — | 5 | — |
| misc/tests | 5 | 1 (t2) | — | 3 notify |

## t2 accuracy — the LLM rubber-stamps

**113/114 t2 verdicts are `notify`.** The single digest was a synthetic
smoke test. Zero real alerts got digest/suppress from the LLM.

Chronic conditions that should have digested — per the prompt's own
"digest = real but not urgent, standing states" rule — were paged:

- `Disk temperature high` — NVMe >55C, refiring daily all week.
  LLM: "immediate airflow/enclosure check needed" ×47
- `Host swap exhaustion` — swap >99% on aurora/ghost, days-long.
  LLM: "critical, immediate investigation needed" ×33
- `DH — Site probe STALE` — flapping. LLM: "potential outage" ×31

None of these were *wrong* per se — but they're standing states, and the
prompt asks for digest on standing states. The model evaluates each alert
in isolation; `recent` (last 5 verdicts for the rule) isn't enough context
for it to recognize chronic vs acute.

## Fail-opens

16/1,123 (1.4%) — mostly pre-ollama-wiring test alerts + a few early
timeouts. Not a concern.

## Latency

t2 verdicts run 10–29s (median ~15s) on the 5700G — acceptable for warning
pages; keep_alive=10m means cold bursts pay ~20s+ (user already tuned
24h→10m for RSS/swap pressure).

## Bottom line: needs-tuning — do NOT flip MODE=enforce yet

Enforce would change almost nothing: t2 votes notify ~always, so every
warning that reaches it still pages. All real filtering today is t1
(dedup caught ~80 refires; digest_rules caught 233 Sanoid warnings).

Before re-review, pick one:

1. **Prompt fix (cheap)**: pass refire count + first-seen age into the
   LLM context and add "if this fingerprint has fired repeatedly in the
   last 24h, prefer digest" to the rules. Gives the model the standing-
   state signal it currently lacks.
2. **Deterministic fix (free)**: move chronic rules — `Disk temperature
   high`, `Host swap exhaustion`, `DH — Site probe STALE` — into
   `digest_rules` in rules.json. They'd digest on refire (first firing
   still pages via dedup window). Recommended — deterministic > model
   judgment for known-chronic signals.

verdict: needs-tuning — t2 notifies 99% of the time; encode chronic rules
in tier-1, then re-review.
