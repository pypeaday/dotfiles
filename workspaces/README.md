# Workspace Manager (`ws`)

`ws` manages persistent scopes of work above Git branches. A workspace can hold
detached control checkouts, disposable PR review checkouts, and normal
branch-backed development checkouts from several repositories.

## Installation

`uv` is required. Stow this package so `~/.local/bin/ws` and `ws.py` are on the
expected path.

## Model

```text
~/projects/work.workspaces/pr-review-batch/
|-- .workspace.json
|-- control/          detached at origin/main
|-- pr-123/           detached at a fetched PR ref
`-- bug-fix/          branch-backed development checkout
```

- **Workspace**: The persistent scope and agent/tmux session.
- **Checkout**: A Git worktree inside a workspace.
- **Detached checkout**: A branch-free control or review checkout.
- **Existing checkout**: A worktree attached to an existing branch.
- **New checkout**: A new branch created from a specified start point.

Workspace metadata records each checkout's source repository, ref, mode, role,
and whether it is disposable. Git remains the source of truth for branch,
working-tree, and unpushed state.

## TUI

```bash
ws tui
```

The TUI lists workspaces and checkouts, creates all three checkout types, opens
the selected scope in tmux, and performs guarded cleanup. Each workspace has one
readable tmux session. Opening a checkout creates or reuses a window for that
checkout inside the workspace session.

| Key | Action |
| --- | --- |
| `n` | Create a workspace |
| `a` | Add a checkout |
| `d` | Remove the selected checkout or workspace |
| `o` / `Enter` | Open the selected checkout or workspace in tmux |
| `r` | Refresh |
| `?` | Show help |
| `q` | Quit |

Removal refuses dirty worktrees and branches with unpushed commits. The TUI
requires a second explicit confirmation before forced removal.

## CLI

Create an empty orchestration workspace:

```bash
ws create work pr-review-batch "Review the current PR queue"
```

Add a detached control checkout:

```bash
ws worktree add work pr-review-batch /path/to/repo \
  --detach --ref origin/main --name control --role control
```

Add a disposable detached PR checkout after fetching its ref:

```bash
git -C /path/to/repo fetch origin pull/123/head:refs/ws/pr-123
ws worktree add work pr-review-batch /path/to/repo \
  --detach --ref refs/ws/pr-123 --name pr-123 --role review --ephemeral
```

Create a development branch:

```bash
ws worktree add work infra-debug /path/to/repo \
  --new-branch debug/networking --ref origin/main --name networking
```

Attach an existing branch:

```bash
ws worktree add work infra-debug /path/to/repo existing-branch
```

When run inside a workspace or one of its checkouts, `ws worktree add` infers
the area and workspace:

```bash
ws worktree add --repo-path /path/to/repo \
  --detach --ref origin/main --name control --role control
```

Agent-friendly commands accept exact repository paths and can emit JSON:

```bash
ws worktree add work review /path/to/repo \
  --detach --ref refs/ws/pr-123 --name pr-123 --role review --json
ws worktree list work review --json
```

Show workspace activity and safety statistics:

```bash
ws stats
ws stats --json
ws stats --stale-days 14
```

Statistics include workspace, checkout, repository, role, and mode counts;
dirty checkouts and changed files; commits ahead and unknown push states; and
last-commit age and stale checkout counts. The TUI shows the same statistics.

Open an agent-ready checkout rather than the workspace container:

```bash
ws open pr-review-batch --checkout control
```

## Other commands

```bash
ws list
ws status -v
ws worktree list [area] [workspace]
ws worktree remove [area] [workspace] [checkout]
ws workspace remove [area] [workspace]
ws worktree git
```

Use `--force` on removal only when losing local changes or unpushed commits is
intentional.
