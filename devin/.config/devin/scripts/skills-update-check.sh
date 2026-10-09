#!/usr/bin/env bash
# SessionStart hook: report pending upstream commits in mattpocock/skills.
#
# Fetches at most once per day (stamp file), but reports every session while
# commits are pending so the offer to update stays live. Prints hook JSON on
# stdout; always exits 0 so session start is never blocked.

set -uo pipefail

REPO="$HOME/projects/mattpocock-skills"
STAMP="${XDG_CACHE_HOME:-$HOME/.cache}/devin-skills-fetch.stamp"
INTERVAL=86400

[ -d "$REPO/.git" ] || exit 0

now=$(date +%s)
last=$(cat "$STAMP" 2>/dev/null || echo 0)
if [ $((now - last)) -ge "$INTERVAL" ]; then
  mkdir -p "$(dirname "$STAMP")"
  echo "$now" > "$STAMP"
  git -C "$REPO" fetch --quiet origin 2>/dev/null || exit 0
fi

behind=$(git -C "$REPO" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
[ "$behind" -gt 0 ] 2>/dev/null || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"The mattpocock/skills repo has %s new upstream commit(s) not yet installed. Offer to run /update-skills to apply them."}}\n' "$behind"
