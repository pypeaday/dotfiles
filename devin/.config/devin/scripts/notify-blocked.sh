#!/usr/bin/env bash
# PermissionRequest hook: ping the host desktop when an agent in a herdr pane
# waits on an approval. Prints no decision, so the normal prompt still runs.
# Always exits 0.

set -u

[ "${HERDR_ENV:-}" = "1" ] || exit 0
command -v distrobox-host-exec >/dev/null 2>&1 || exit 0

summary="$(cat 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
tool = str(d.get("tool_name", "tool"))
ti = d.get("tool_input") or {}
hint = ti.get("command") or ti.get("file_path") or ti.get("pattern") or ""
hint = str(hint).replace("\n", " ")[:100]
print(f"{tool}: {hint}" if hint else tool)
' 2>/dev/null || true)"

name="$(basename "${PWD:-$HOME}")"
distrobox-host-exec notify-send --app-name=Devin "Devin needs approval" "${name}: ${summary:-pending}" >/dev/null 2>&1 || true
exit 0
