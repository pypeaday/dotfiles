#!/usr/bin/env bash
# triage-review.sh — periodic shadow-mode review of alert-triage verdicts.
# Pulls verdicts.jsonl from ghost, runs a headless devin session to judge
# whether t2 (ollama) calls are good enough to flip MODE=enforce, writes a
# report, and pings the desktop. Fired by devin-triage-review.timer.
set -uo pipefail

DATE="$(date +%F)"
STATE="$HOME/.local/share/devin/cli"
LOGDIR="$STATE/dream-logs"
WORK="$STATE/triage-review/$DATE"
REPORT="$HOME/.config/devin/docs/TRIAGE-REVIEW-$DATE.md"
DEVIN="$HOME/.local/bin/devin"
mkdir -p "$WORK" "$LOGDIR"

# fetch the verdict log (ghost hostname flaps; ghost2 is the IP alias)
for H in ghost ghost2; do
  if ssh -o ConnectTimeout=5 "$H" true 2>/dev/null; then
    scp -q "$H:/tank/encrypted/docker/alert-triage/data/verdicts.jsonl" \
      "$WORK/verdicts.jsonl" && break
  fi
done

if [ ! -s "$WORK/verdicts.jsonl" ]; then
  distrobox-host-exec notify-send "Triage review $DATE" \
    "FAILED: could not pull verdicts.jsonl from ghost" 2>/dev/null || true
  exit 1
fi

"$DEVIN" -p --permission-mode smart --respect-workspace-trust false -- \
  "You are reviewing a homelab alert-triage service running in SHADOW mode \
(every alert still notifies; verdicts are advisory only). Read \
$WORK/verdicts.jsonl — one JSON object per line: ts, rule, severity, \
verdict (notify|digest|suppress), tier (t1=rules, t2=ollama gemma3:4b), \
reason, ms. Write a report to $REPORT.md covering: (1) counts by \
verdict+tier; (2) every t2 verdict where the LLM's call looks WRONG \
(e.g. digested a real outage, would have suppressed something actionable) \
— quote the rule+reason; (3) fail-open count and causes; (4) a bottom-line \
recommendation: safe to flip MODE=enforce, or what needs tuning first \
(rules.json digest/suppress lists, prompt, model). Keep it under 100 lines. \
When done, reply with ONLY one line: 'verdict: <safe-to-enforce|needs-tuning> — <why>'" \
  >> "$LOGDIR/triage-review-$DATE.log" 2>&1

summary="$(tail -5 "$LOGDIR/triage-review-$DATE.log" | grep -o 'verdict:.*' | tail -1)"
distrobox-host-exec notify-send "Triage review $DATE" \
  "${summary:-review done} — $REPORT.md" 2>/dev/null || true
exit 0
