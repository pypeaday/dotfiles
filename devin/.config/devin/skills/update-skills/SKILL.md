---
name: update-skills
description: "Update the installed mattpocock/skills to the latest upstream version. Use when the user wants to update, refresh, or pull new versions of the installed agent skills."
allowed-tools:
  - exec
---

Update the skills installed from `~/projects/mattpocock-skills` into `~/.agents/skills`.

1. Run `old=$(git -C ~/projects/mattpocock-skills rev-parse HEAD)` to record the current commit.
2. Run `git -C ~/projects/mattpocock-skills pull`. If it fails on local changes, show the user `git -C ~/projects/mattpocock-skills status` and stop. `devin-sync.sh` is untracked, so a clean tree is expected.
3. Run `~/projects/mattpocock-skills/devin-sync.sh`. It re-links `~/.claude/skills`, re-copies and re-patches `~/.agents/skills`, and removes skills upstream deleted.
4. Report what changed: `git -C ~/projects/mattpocock-skills log --oneline "$old"..HEAD`, plus the script's installed/removed lines.
