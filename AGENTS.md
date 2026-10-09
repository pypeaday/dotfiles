# AGENTS

## Repo purpose

Personal dotfiles managed with GNU Stow. Each package directory mirrors `$HOME`
layout (`nvim/.config/nvim/`, `zsh/.zshrc`, ...). Synced to Forgejo at
`ssh://git@git-ghost:222/nic/dotfiles.git`.

## Entrypoints

- `./install` — re-stows every package listed in `dotfiles.txt`, then applies
  host-specific packages (`iron` when `$USER` contains `3`, `fin` for `81`,
  otherwise `zsh` + `git`). Use it, not bare `stow`.
- `stow <package>` — link one package; `stow -D <package>` — unlink.
- `stow -n <package>` — dry-run before changing links.

## Conventions

- Add a package: create `<name>/` mirroring the target `$HOME` path, add
  `<name>` to `dotfiles.txt`, run `./install`.
- User config lives here; **system provisioning does not**. apt packages,
  `/usr/local` binaries, `/etc` files belong in
  `~/projects/personal/ansible-playbooks` (`just dev` inside the box).
- Distrobox shares `$HOME` with the host, so everything stowed here is also
  live inside every container. Gate container-only behavior on
  `$CONTAINER_ID` (see `docker` role snippet writing `.bashrc.d/`).

## Gotchas

- **Folded dirs**: stow folds directories, so some `$HOME` paths are links
  into this repo — e.g. `~/.local/bin` → `workspaces/.local/bin`. A relative
  symlink created inside a folded dir resolves relative to the repo, not
  `~/.local` — emit absolute symlink targets (the `opencode` npm install hit
  this).
- **`private/` holds live API keys** — gitignored; keep it that way.
- `workspaces/.local/bin/` contains installed binaries, not source —
  gitignored.
- SSH topology: `ghost` = nic shell + docker context (skm RSA key);
  `git-ghost` = Forgejo git (ed25519). Remotes must use `git-ghost`.
- Forgejo (ghost) is the primary remote; a GitHub mirror publishes the
  `docs/` mkdocs site to pypeaday.github.io/dotfiles.
- `~/.zshrc`, `~/.bashrc` are plain files (not stowed links) edited by
  installers — check both stow source and live file when debugging PATH.

## Pointers

- `docs/` — mkdocs site with per-tool notes (humans).
- `distrobox/.config/distrobox/distrobox.ini` — `distrobox assemble` box
  definitions.
