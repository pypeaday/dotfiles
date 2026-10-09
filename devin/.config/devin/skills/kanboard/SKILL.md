---
name: kanboard
description: "Work in the user's self-hosted Kanboard (kanboard.paynepride.com) — the personal kanban used to track work. Use when creating, moving, updating, or closing tasks/tickets, listing what's on a board, adding comments or tags, or checking due/overdue work. Boards: Homelab, Homelab Cleanup, Work, Dev, Digital Harbor, Gaming, Automated Tickets, Pilgrim's Creek."
---

# Kanboard

Self-hosted Kanboard on ghost. UI at `https://kanboard.paynepride.com`
(direct: `http://ghost:8009`). Stack lives in
`homelab-mono/compose/ghost/kanboard/`.

## API

JSON-RPC 2.0 at `https://kanboard.paynepride.com/jsonrpc.php`. HTTP basic
auth — user `jsonrpc`, password = token at
`~/.local/share/devin/kanboard-token` (same token exported as
`KANBOARD_TOKEN` in `homelab-mono/.envrc`).

All ids are integers — pass numbers, not strings. Response shape:
`{jsonrpc, id, result}` or `{error: {message}}`; `result: false` means no
change happened (e.g. bad column), not a transport error.

```bash
kb() {  # kb <method> '<params-json>'
  curl -s -u "jsonrpc:$(cat ~/.local/share/devin/kanboard-token)" \
    -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg m "$1" --argjson p "${2:-"{}"}" \
        '{jsonrpc:"2.0",method:$m,id:1,params:$p}')" \
    https://kanboard.paynepride.com/jsonrpc.php | jq '.result // .error'
}
```

## Boards

| Project | ID | Columns |
|---|---|---|
| Homelab | 8 | Backlog → Ready → WIP → Done |
| Homelab Cleanup | 17 | Backlog → Ready → WIP → Done |
| Work | 16 | Ready → WIP → Done (no Backlog) |
| Dev | 11 | Backlog → Ready → WIP → Done |
| Automated Tickets | 15 | Backlog → Ready → WIP → Done |
| Digital Harbor | 3 | fetch `getColumns` |
| Gaming | 12 | fetch `getColumns` |
| Pilgrim's Creek | 14 | fetch `getColumns` |
| Meta (empty) | 1 | fetch `getColumns` |

Column ids are globally unique per board — get them with `getColumns`.
`QUADTASK_KANBOARD_PROJECT_ID=5` in `homelab-mono/.envrc` is stale; project
5 no longer exists.

Board URL: `https://kanboard.paynepride.com/board/<project_id>`
Task URL: `https://kanboard.paynepride.com/?controller=TaskViewController&action=show&task_id=<id>`

## Methods by intent

- **Board snapshot** (columns + tasks): `getBoard {project_id}`
- **List tasks**: `getAllTasks {project_id, status_id: 1}` (1=open,
  0=closed); overdue: `getOverdueTasks`
- **Search**: `searchTasks {project_id, query}` — Lucene-ish:
  `title:"foo"`, `status:open`, `assignee:nic`
- **Read one**: `getTask {task_id}` (includes swimlane/column ids)
- **Create**: `createTask {title, project_id, description?, column_id?,
  owner_id?, date_due? "YYYY-MM-DD", category_id?, color_id?}` → returns
  task_id
- **Move**: `moveTaskPosition {project_id, task_id, column_id, position: 1,
  swimlane_id}` — `swimlane_id` is required; get it from `getTask` first
- **Update fields**: `updateTask {id, title?/description?/date_due?/...}`
- **Close / reopen / delete**: `closeTask {task_id}` / `openTask` /
  `removeTask` (destructive — confirm first)
- **Comment**: `createComment {task_id, user_id: 4, content}`;
  `getAllComments {task_id}`
- **Tags**: `setTaskTags {project_id, task_id, tags: [...]}`;
  `getTaskTags {task_id}`

## Gotchas

- **Done column ≠ done.** Tasks sitting in Done still have `is_active=1`;
  run `closeTask` to actually complete them (drops them off the board).
- Users: `4` = nic (owns every board), `1` = dumbledore. Assign with
  `owner_id`.
- `color_id` accepts names: yellow, blue, green, purple, red, orange,
  grey, brown, deep_orange, pink, teal, cyan, lime.

## Agent work convention

- Tag **`agent-ready`** marks a card an agent can execute end-to-end.
  Tag with `setTaskTags`.
- Pick work from the **Ready** column carrying `agent-ready`. Claim it by
  moving to WIP and setting `owner_id: 4` — the board shows it as taken.
- Comment progress via `createComment`; on finish move to Done **and**
  `closeTask`, then tell the user the task URL.
- Homelab board (8) swimlanes: Infrastructure / Services / Observability /
  Projects. File new infra chores into the matching lane's Backlog.
- Dependencies use task links (`createTaskLink`, link 3 = "is blocked
  by") — check a card's links before picking it up; `relationgraph`
  renders them on the project page.

## Agent dispatch (decided: no extra infra)

Evaluated Amp orbs/runners + a kanboard-polling daemon — rejected for the
homelab. Current model: **kanboard is the queue, herdr panes are the
runners**. An agent in a herdr/devin session picks `agent-ready` cards from
Ready and works them one at a time. If unattended polling is ever wanted:
`devin -p "<prompt>" --permission-mode smart` runs headless (cron on aurora,
not ghost — devin lives on the desktop).
