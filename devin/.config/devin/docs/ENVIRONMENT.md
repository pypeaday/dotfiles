# Environment

Machines and runtimes Devin sessions run against. Read when a task touches hosts, networking, mounts, or paths outside this container.

## Machines

- **aurora** — the Fedora host (kernel 6.19.x, fc44). Owns the desktop, browser, notifications, and ZFS storage (`~/zfs-ops`).
- **UbuntuDev** — the distrobox container sessions run in. Ubuntu 24.04, podman-backed, shares `$HOME` with the host. `container=podman`, `CONTAINER_ID=UbuntuDev` in env.
- Homelab machines — on Tailscale (`tailscale` works inside this container; mesh includes aurora, ghost, ghost-vault, phones):
  - **ghost** (LAN 192.168.1.9, tailnet 100.64.184.5) — docker host. Runs **Forgejo**: git ssh on `:222`, web/API at `https://git.paynepride.com` (also `http://ghost:3007` direct). Runs a Forgejo Actions runner, the homelab-stack compose dir (`/tank/encrypted/nas/code/homelab-compose/ghost/homelab-stack`), and traefik fronting `*.paynepride.com` sites. `ssh ghost` works as nic. Most stacks' compose files live locally in `~/projects/personal/homelab-mono/compose/ghost/<stack>/` (not a git checkout on ghost); deploy with `docker --context ghost compose up -d` from that dir (container labels `com.docker.compose.project.config_files` show where each one was started from — some are still from the old `homelab-compose` path). Never use `docker logs --since` on ghost: with unrotated json logs it scans whole multi-GB files.
  - **ghost-vault** (tailnet 100.78.53.63) — TODO: role.
  - **pihole** — `pihole3` on tailnet (100.103.93.16, LAN 192.168.1.4). A *different box* from the old pihole at 192.168.1.3, which is off. DNS on :53, admin UI on :443 (`http://pihole3` upstreamed by traefik as pihole.paynepride.com). **Admin API is open from the LAN — no password set.** `ssh pihole` works (dumbledore@pihole3) but the `pihole-dumbledore` skm key is NOT authorized on pihole3 — add `~/.skm/pihole-dumbledore/id_rsa.pub` manually. Query log API: `GET /api/queries?domain=*wildcards-required*&length=N` — in-memory only (~36h); disk DB (~2GB, back to July) not reachable via API.
  - **babyblue**, **babyblue-aurora** — currently offline.
- **git-ghost** = ssh alias → `git@ghost:222`; repo remotes point at it. The `forgejo` MCP server (forgejo-mcp v3.1.0, docker) gives agents issue/PR/Actions tools against `https://git.paynepride.com`; its token lives at `~/.local/share/devin/forgejo-token` (local file, never committed).

## Crossing the container boundary

- Host commands: `distrobox-host-exec <cmd>` runs on aurora (`notify-send` confirmed working).
- Open URLs in the host browser: `distrobox-host-exec xdg-open <url>` (e.g. MCP OAuth flows).
- `host-spawn` is also available; used to run host binaries (e.g. `npx` for the context7 MCP).

## Layout

- `~/dotfiles` — stow-managed config repo. `~/.config/devin` and `~/.config/herdr` hold per-entry symlinks into `~/dotfiles/devin/` and `~/dotfiles/herdr/`; edit config at the dotfiles path, not through the symlink.
- `~/projects/personal/` — all working repos (see `PROJECTS.md`).
- `~/projects/mattpocock-skills/` — clone of the skills repo; `devin-sync.sh` syncs it into `~/.agents/skills/` (copies patched for Devin) and `~/.claude/skills/` (symlinks).
- `~/.agents/skills/` — the installed mattpocock skills.
- `~/.config/devin/skills/` — personal skills, dotfiles-managed.
- `~/.config/devin/scripts/` — hook scripts, dotfiles-managed.

## Agent runtime

- Sessions run inside herdr panes (`HERDR_ENV=1`; workspaces `websites`, `infra`, `homelab`). `herdr agent list` shows live agents; `/resume <session-id>` resumes a past session.
- To verify UI/terminal-app behavior (nvim keymaps, TUIs): `herdr pane split --current --direction right --cwd "$PWD" --no-focus`, then `pane run`/`send-keys`/`read` to drive and screenshot it. Headless nvim can't test VeryLazy-gated keymaps — it never fires.
- MCP servers configured: `git` (docker), `context7` (npx via host-spawn), `cloudflare-docs`, `cloudflare-api`.
- `SessionStart` hook reports pending mattpocock/skills upstream commits; `/update-skills` applies them.
- `Stop` hook pings the host desktop when an agent turn finishes inside a herdr pane.
- Headless runs: `devin -p "prompt"` for scheduled/scripted use.
