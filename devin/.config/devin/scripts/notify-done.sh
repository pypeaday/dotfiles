#!/usr/bin/env bash
# Stop hook: ping the host desktop when an agent turn finishes inside a herdr
# pane. Skips when a previous stop hook is still active to avoid double pings.
# Always exits 0; never blocks the session.

set -u

[ "${HERDR_ENV:-}" = "1" ] || exit 0
command -v distrobox-host-exec >/dev/null 2>&1 || exit 0

payload="$(cat 2>/dev/null || true)"
printf '%s' "$payload" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

name="$(basename "${PWD:-$HOME}")"
distrobox-host-exec notify-send --app-name=Devin "Devin idle" "Agent finished in ${name}" >/dev/null 2>&1 || true
exit 0
