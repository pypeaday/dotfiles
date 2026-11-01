---
name: alert-triage
description: "Build, run, and tune the alert-filter pipeline: SigNoz alert rules → webhook → alert-triage service on ghost → LLM verdict (notify / digest / suppress) → Gotify. Use when the user asks to filter/dedupe/smarten SigNoz or Gotify notifications, route alerts through an LLM first, or mentions the alert triage/filter/bridge service."
---

# Alert Triage

A filter layer between SigNoz (the OTel nexus — all alerts land here) and Gotify
(the pager). The goal: no raw alert reaches the user until something with
judgment has looked at it — dedupe, context, classify, maybe suppress.

## Pipeline

```
SigNoz rule fires ──webhook──► alert-triage (ghost) ──┬─► Gotify  (verdict: notify)
        POST /alert                                  ├─► digest queue (verdict: digest)
        JSON payload                                 └─► drop + log  (verdict: suppress)
                                                     │
                                                     └── every path appends one
                                                         structured log line
                                                         {"type":"alert.triage",...}
```

Two-tier decision inside the service:

- **Tier 1 — deterministic rules** (no LLM): dedupe same rule+labelset within
  cooldown (e.g. 30min), severity floor, known-flapper list, "resolved" echoes.
  Cheap and predictable — most volume dies here.
- **Tier 2 — LLM verdict** for anything surviving tier 1: POST to ollama
  (`OLLAMA_BASE`, model e.g. `gemma3:4b`), prompt = alert payload + recent firing
  history + optional context lines fetched from SigNoz. Response is strict JSON:
  `{"verdict": "notify|digest|suppress", "reason": "<=160 chars", "severity": "..."}`.

**Fail-open is non-negotiable**: if the LLM is unreachable/slow (>10s timeout),
the alert passes through to Gotify marked `unfiltered`. A broken filter must
never silently eat pages.

## Hard environment facts

- SigNoz is self-hosted **v0.64.0** — MCP dashboard/alert/channel tools 404.
  All SigNoz-side work goes through the legacy REST API at
  `https://signoz.paynepride.com` (token in `~/.local/share/devin/signoz-token`,
  header `SIGNOZ-API-KEY`):
  - list channels: `GET /api/v1/notificationChannels`
  - create webhook channel: `POST /api/v1/channels` (`{"name":"Alert Triage",
    "type":"webhook","data":{"url":"http://ghost:PORT/alert"}}`)
  - point rules at it: `PUT /api/v1/rules/<id>` with `preferredChannels`
  - **capture a real webhook payload first** — the v0.64 webhook body shape is
    not documented; log the raw body before writing the parser.
- Gotify bridge runs on ghost at `http://localhost:2346` — same pattern
  `sync-harbor.sh` uses:
  `POST /message?token=$GOTIFY_TOKEN -F title= -F message= -F priority=`.
  Token lives in `~/.config/zfs-ops/sync.env` on ghost (GOTIFY_TOKEN).
- ghost has **no ollama** today — `OLLAMA_BASE` is a config decision (run a
  container, or point at another host). The `LLaMA` dir in media/downloads is
  old GGUF weights, unrelated.
- Service home: candidate repos are `zfs-ops` (ghost infra scripts,
  where sync-harbor.sh + zfs-metrics.sh live) or `homelab-mono`. Decide at
  build time; don't guess.

## Build recipe

1. **Shadow first.** Service accepts webhooks, evaluates both tiers, logs the
   verdict it *would* take, and always forwards to Gotify tagged `[shadow]`.
   Only flip to enforce after a week of sane decisions in the log.
2. Minimal endpoints: `POST /alert` (SigNoz webhook), `GET /decisions` (recent
   verdicts for debugging), `GET /healthz`.
3. State: append-only JSONL (`verdicts.jsonl`) — enough for dedupe and the
   digest; no DB needed for v1.
4. Digest: a `*/30min` flush posts one Gotify message summarizing digested
   alerts (count + top reasons), not one message per alert.
5. Structured log line per verdict (`type=alert.triage`, fields: rule, verdict,
   reason, tier, latency_ms) — ship it via otel like site-monitor does, so the
   filter itself is observable inside SigNoz and can be alerted on if it dies.
6. Escalation escape hatch: `severity=critical` rules can be configured to
   bypass tier 2 entirely (always notify immediately, LLM still annotates).

## Testing

- Replay: keep the last N raw webhook bodies (`raw/`), `POST /alert` them back
  to see verdicts without touching SigNoz.
- Dry-run a rule's query via `POST /api/v3/query_range` before wiring it to the
  channel (same technique used to build the DH site alerts).
- Force a fire: temporarily point one benign rule at the channel, or replay a
  captured payload.

## Ops rules for the agent

- New alert source? Route it through the channel, not around it. SigNoz is the
  nexus; exceptions (like sync-harbor.sh's direct gotify curl) should migrate in
  over time, not fork further.
- Tuning loop is data-driven: read `verdicts.jsonl`, find rules producing
  suppress/digest churn, either fix the underlying thing or add a tier-1 rule —
  don't just bump thresholds blindly.
- The sanoid capacity warning is a known example of a *standing* alert that
  should digest, not page — good fixture for the flapper/standing list.
