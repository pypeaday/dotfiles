---
name: task-management
description: "Decide where a piece of work should be tracked for the user. Use when starting, finishing, or handing off work that needs a ticket/card, when the user says 'file a task'/'track this'/'add it to the board', when a manual step remains that an agent can't do, or when unsure whether something belongs in Forgejo issues vs Kanboard."
---

# Task management — where work is tracked

Three tracking surfaces, one rule each:

| Surface | For | How |
|---|---|---|
| **Forgejo issues** | work owned by a repo | `forgejo` MCP tools |
| **Kanboard** | cross-project, infra chores, personal | invoke `kanboard` skill |
| **todo_write** | inside this session only | never external |

## Forgejo issues

Work that belongs to a repository — a bug, feature, or refactor whose code
lives in one repo — files as an issue **on that repo**.

- Repos live on ghost: remote `git-ghost` = `git@ghost:222`, web/API at
  `https://git.paynepride.com` (token: `~/.local/share/devin/forgejo-token`).
- Agents use the `forgejo` MCP server tools — no extra auth setup.
- PRs auto-close issues via `fixes #N` in the body — link them.
- If the work is also a visible chunk of the user's week, mirror a Kanboard
  card that links to the issue URL.

## Kanboard

Everything that isn't repo-owned: infra chores, device work, multi-repo or
non-code tasks, personal errands. Invoke the `kanboard` skill for the API;
pick the board by domain:

| Board | ID | Filed here |
|---|---|---|
| Homelab | 8 | infra/network/pihole/docker chores |
| Homelab Cleanup | 17 | stack-maturity debt only |
| Work | 16 | day-job items |
| Dev | 11 | dev work not owned by one repo |
| Digital Harbor | 3 | client work |
| Gaming / Pilgrim's Creek | 12 / 14 | those hobbies |

**Never** file to Automated Tickets (15) — it's the GitHub-stars
automation feed, not agent work.

## When to file vs when not

File a ticket when:

- the user asks to track something,
- a manual step remains that no agent can do (e.g. physical access,
  console login) — describe the step verbatim and include any material it
  needs (pubkey, command, path),
- work is being interrupted mid-task — the card captures state for the
  next session.

Skip the ticket when: the work is done, it's trivia, or the user is just
asking a question.

## Closing the loop

When tracked work finishes, update the tracker the same turn:

- Kanboard: move to Done *and* `closeTask` (Done column alone leaves it
  open).
- Forgejo: comment the outcome; close if no PR will.
- In the reply, cite the tracker link so the user can check it.
