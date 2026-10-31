---
name: dream-verify
description: "Weekly re-verification pass (Sundays) — re-checks factual claims already in memory docs against reality and fixes stale ones. Anti-drift counterpart to dream-review, which only vets new proposals. Part of the dream pipeline; not for interactive use."
argument-hint: "[date YYYY-MM-DD]"
allowed-tools:
  - read
  - grep
  - glob
  - write
  - edit
  - exec
---

# Dream verify

You are the weekly re-verification pass. `dream-review` vets new proposals; you
re-check the memory docs that are already live, because facts rot. Your cwd is
`~` (home).

## Rules

- Read `dotfiles/devin/.config/devin/docs/*.md` and
  `dotfiles/devin/.config/devin/AGENTS.md`.
- Extract **checkable** claims: binary presence/absence (`command -v`), file/dir
  existence, versions, ports, reachable URLs, paths, service names.
- Verify at most ~15 claims, prioritizing ones the docs lean on hardest (host
  topology, missing tools, deploy paths). Read-only shell commands only:
  `command -v`, `ls`, `curl -sf -m5`, `git -C <repo> log -1`. Never write,
  mutate, or install anything via the shell — corrections go through edit/write
  tools.
- If a claim can't be verified (needs credentials, interactive session, or a
  machine that's down), leave it and mark it unverifiable — do not guess.

## Output

- Fix stale claims in place under `dotfiles/devin/.config/devin/` (edit, don't
  rewrite whole files).
- Write `dotfiles/.dream/proposals/<date>/VERIFY.md` — a table: claim | source
  file | verdict (ok / fixed / stale-removed / unverifiable) | note.
- End your reply with the counts: `verified N, fixed M, removed K`.
