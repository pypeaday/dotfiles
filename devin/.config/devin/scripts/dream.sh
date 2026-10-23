#!/usr/bin/env bash
# dream.sh — nightly consolidation pass over devin sessions.
# Exports new sessions to ~/dotfiles/.dream/inbox/<date>/, then runs a headless
# devin session that distills them into proposals under .dream/proposals/<date>/
# (see ~/.config/devin/skills/dream/SKILL.md). Runs inside UbuntuDev via
# systemd --user timer on the host (devin-dream.timer).
set -uo pipefail

DATE="$(date +%F)"
STATE="$HOME/.local/share/devin/cli"
WM="$STATE/dream-watermark"
DOTFILES="$HOME/dotfiles"
INBOX="$DOTFILES/.dream/inbox/$DATE"
OUT="$DOTFILES/.dream/proposals/$DATE"
LOGDIR="$STATE/dream-logs"
DEVIN="$HOME/.local/bin/devin"

mkdir -p "$INBOX" "$OUT" "$LOGDIR"
MARK="$(cat "$WM" 2>/dev/null || echo 0)"
NOW="$(date +%s)"

python3 - "$MARK" "$INBOX" <<'PY'
import json, os, sqlite3, sys

mark, inbox = int(sys.argv[1]), sys.argv[2]
db = sqlite3.connect(
    "file:%s?mode=ro" % os.path.expanduser("~/.local/share/devin/cli/sessions.db"),
    uri=True)
db.row_factory = sqlite3.Row

sessions = db.execute(
    """SELECT id, title, working_directory, last_activity_at FROM sessions
       WHERE last_activity_at > ? AND hidden = 0
       ORDER BY last_activity_at DESC LIMIT 12""", (mark,)).fetchall()

kept = 0
for s in sessions:
    first = db.execute(
        """SELECT content FROM prompt_history
           WHERE session_id = ? AND is_shell = 0
           ORDER BY timestamp LIMIT 1""", (s["id"],)).fetchone()
    if first and first["content"].startswith("DREAM-"):
        continue  # skip our own dream sessions
    rows = db.execute(
        """SELECT chat_message FROM message_nodes
           WHERE session_id = ? ORDER BY node_id""", (s["id"],)).fetchall()
    with open(os.path.join(inbox, s["id"] + ".md"), "w") as f:
        f.write("# session %s\n# title: %s\n# cwd: %s\n\n"
                % (s["id"], s["title"], s["working_directory"]))
        prev = None
        seen_user = set()
        for r in rows:
            try:
                msg = json.loads(r["chat_message"])
            except Exception:
                continue
            role = msg.get("role", "?")
            if role == "system":
                continue  # skip repeated system/rules/skills preamble
            content = msg.get("content", "")
            if isinstance(content, list):
                content = " ".join(
                    c.get("text", "") if isinstance(c, dict) else str(c)
                    for c in content)
            if not isinstance(content, str):
                content = str(content)
            content = content.strip()
            if not content or (role, content) == prev:
                continue  # skip empty or consecutive duplicate nodes
            if role == "user":
                if content in seen_user:
                    continue  # skip resume echoes of the same prompt
                seen_user.add(content)
            prev = (role, content)
            cap = 800 if role == "tool" else 4000
            if len(content) > cap:
                content = content[:cap] + "\n...[truncated]"
            f.write("## %s\n%s\n\n" % (role, content))
            if f.tell() > 40000:
                f.write("[truncated: session too large]\n")
                break
    kept += 1
print("exported %d sessions" % kept)
PY

count="$(find "$INBOX" -name '*.md' | wc -l)"
if [ "$count" -eq 0 ]; then
  echo "[$DATE] no new sessions; skipping" >> "$LOGDIR/dream.log"
  echo "$NOW" > "$WM"
  exit 0
fi

cd "$HOME"
"$DEVIN" -p --permission-mode smart --respect-workspace-trust false \
  -- "DREAM-RUN $DATE — read dotfiles/devin/.config/devin/skills/dream/SKILL.md and follow it for inbox date $DATE" \
  > "$LOGDIR/dream-$DATE.log" 2>&1
rc=$?

if [ "$rc" -ne 0 ]; then
  distrobox-host-exec notify-send "Devin dream $DATE FAILED" \
    "dream stage rc=$rc — see $LOGDIR/dream-$DATE.log" 2>/dev/null || true
  exit "$rc"
fi
echo "$NOW" > "$WM"

"$DEVIN" -p --permission-mode smart --respect-workspace-trust false \
  -- "DREAM-REVIEW $DATE — read dotfiles/devin/.config/devin/skills/dream-review/SKILL.md and follow it for proposals date $DATE" \
  >> "$LOGDIR/dream-$DATE.log" 2>&1

# Audit trail: commit whatever the reviewer applied under docs/ as a
# 'dream: <date>' commit (git log --grep dream / git revert = undo path).
if git -C "$DOTFILES" status --porcelain -- devin/.config/devin/docs/ | grep -q .; then
  git -C "$DOTFILES" add devin/.config/devin/docs/ &&
    git -C "$DOTFILES" commit -q -m "dream: $DATE auto-applied doc updates" ||
    echo "[$DATE] audit commit failed" >> "$LOGDIR/dream.log"
fi

summary="$(grep -oE 'applied [0-9]+, flagged [0-9]+, rejected [0-9]+' "$LOGDIR/dream-$DATE.log" | tail -1)"
flagged="$(echo "$summary" | grep -oE 'flagged [0-9]+' | grep -oE '[0-9]+')"

# Flagged proposals → a card on the Automated Tickets board so they surface.
if [ "${flagged:-0}" -gt 0 ]; then
  python3 - "$DATE" "$OUT" <<'PY'
import json, os, sys, urllib.request

date, outdir = sys.argv[1], sys.argv[2]
token = open(os.path.expanduser("~/.local/share/devin/kanboard-token")).read().strip()

def kb(method, params):
    req = urllib.request.Request(
        "https://kanboard.paynepride.com/jsonrpc.php",
        data=json.dumps({"jsonrpc": "2.0", "method": method, "id": 1,
                         "params": params}).encode(),
        headers={"Content-Type": "application/json"})
    req.add_header("Authorization",
                   "Basic " + __import__("base64").b64encode(
                       ("jsonrpc:" + token).encode()).decode())
    return json.load(urllib.request.urlopen(req, timeout=15)).get("result")

import glob
flagged_rows = []
for p in sorted(glob.glob(os.path.join(
        os.path.dirname(outdir.rstrip("/")), "*", "REVIEW.md"))):
    day = os.path.basename(os.path.dirname(p))
    try:
        for line in open(p):
            if "| flagged |" in line:
                flagged_rows.append("[%s] %s" % (day, line.strip()))
    except OSError:
        pass
desc = ("Dream flagged proposals for " + date + " — see " +
        outdir + "/REVIEW.md\n\n" + "\n".join(flagged_rows[:20]))

open_tasks = kb("searchTasks", {"project_id": 15,
                "query": 'status:open title:"Dream flagged"'}) or []
if open_tasks:
    kb("createComment", {"task_id": open_tasks[0]["id"], "user_id": 4,
                         "content": desc})
else:
    kb("createTask", {"title": "Dream flagged items", "project_id": 15,
                      "owner_id": 4, "description": desc})
PY
fi

# Sundays: re-verify existing memory facts (anti-drift).
if [ "$(date +%u)" = 7 ]; then
  "$DEVIN" -p --permission-mode smart --respect-workspace-trust false \
    -- "DREAM-VERIFY $DATE — read dotfiles/devin/.config/devin/skills/dream-verify/SKILL.md and follow it for date $DATE" \
    >> "$LOGDIR/dream-$DATE.log" 2>&1
fi

# Metrics line + push to dreams.paynepride.com dashboard on ghost.
METRICS="$STATE/dream-metrics.jsonl"
python3 - "$LOGDIR/dream-$DATE.log" "$DATE" "$count" "$SECONDS" "$METRICS" <<'PY'
import json, re, sys

log_path, date, sessions, dur, out = sys.argv[1:]
try:
    log = open(log_path).read()
except OSError:
    log = ""
rec = {"date": date, "sessions": int(sessions), "duration_s": int(dur)}
m = re.findall(r"applied (\d+), flagged (\d+), rejected (\d+)", log)
v = re.findall(r"verified (\d+), fixed (\d+), removed (\d+)", log)
if m: rec.update(applied=int(m[-1][0]), flagged=int(m[-1][1]), rejected=int(m[-1][2]))
if v: rec.update(verified=int(v[-1][0]), fixed=int(v[-1][1]), removed=int(v[-1][2]))
open(out, "a").write(json.dumps(rec) + "\n")
PY

dates="$(find "$DOTFILES/.dream/proposals" -name REPORT.md -printf '%h\n' 2>/dev/null | xargs -r -n1 basename | sort -r | head -30)"
python3 -c 'import json,sys; print(json.dumps({"dates":sys.argv[1:]}))' $dates > "$STATE/dream-index.json"

DEST=""
for H in ghost ghost2; do
  if ssh -o ConnectTimeout=5 "$H" true 2>/dev/null; then
    DEST="$H:/tank/encrypted/docker/dreams/www/data"; break
  fi
done
push="no-host"
if [ -n "$DEST" ]; then
  ssh "${DEST%%:*}" "mkdir -p /tank/encrypted/docker/dreams/www/data/reports" 2>/dev/null
  rsync -a "$METRICS" "$DEST/metrics.jsonl" &&
  rsync -a "$STATE/dream-index.json" "$DEST/index.json" &&
  rsync -a --delete --exclude '*/devin/' "$DOTFILES/.dream/proposals/" "$DEST/reports/" &&
  push=ok || echo "[$DATE] dashboard push failed" >> "$LOGDIR/dream.log"
else
  echo "[$DATE] ghost unreachable" >> "$LOGDIR/dream.log"
fi

distrobox-host-exec notify-send "Devin dream $DATE" \
  "$count sessions distilled; ${summary:-no counts}; push:$push — $OUT" 2>/dev/null || true
exit 0
