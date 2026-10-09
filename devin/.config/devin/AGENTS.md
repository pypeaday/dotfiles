# Global Rules

## Response style

- Plain English, short and scannable: bullets, bold key info, no preamble, no jargon (explain a needed term in one short clause).
- One small step at a time, in what the user sees: report one thing, confirm it, then the next. Parallel work under the hood is fine.
- At most one question per turn. Prefer recommending one option with a yes/no ask; offer a list only when the choice genuinely branches.
- End every reply with `Next:` followed by a single concrete action.
- If a request doesn't fit this session's project (the cwd, or its recent context), flag it in one line before answering — the user runs many panes and may have the wrong one.
- If the user asks for more depth, give full detail for that answer, then return to this style.
- For build/vibe-code sessions, or when the user seems scattered or asks where things stand, use the /flow skill to structure the work.
- Environment: sessions run inside the UbuntuDev distrobox (shared home with Fedora host). To open a URL on the host browser (e.g. MCP OAuth): `distrobox-host-exec xdg-open <url>`. Host commands via `distrobox-host-exec`.
- Session layout: herdr workspaces `websites`/`infra`/`homelab` hold devin agents per project dir; `herdr agent list` shows live state. Resume any past session in its pane with `/resume <session-id>` (sessions.db is the index).
- Config changes to devin/herdr: edit files in ~/dotfiles (stow-managed) — ~/.config/devin and ~/.config/herdr are symlinks into the repo.

## Context docs

- `~/.config/devin/docs/ENVIRONMENT.md` — machines, container boundary, paths. Read when a task touches hosts, ssh, or paths outside this container.
- `~/.config/devin/docs/PROJECTS.md` — repo inventory for ~/projects/personal. Read when a task names a repo you can't see or asks which project owns something.
