# Tmux Configuration

## Overview

Tmux (Terminal Multiplexer) configuration for session management, window handling, and pane control.

I started with a sane tmux config from github and my [tmux module](https://github.com/pypeaday/dotfiles/tree/main/tmux) in my dotfiles has some customization built into `.tmux.conf.local`

## Installation

```bash
cd ~/dotfiles
stow tmux
```

Files: `~/.tmux.conf` and `~/.tmux.conf.local`

## Key Bindings

Prefix: `Ctrl+b`

| Shortcut | Action |
|----------|--------|
| `Ctrl+b c` | New window |
| `Ctrl+b n/p` | Next/Previous window |
| `Ctrl+b %` | Vertical split |
| `Ctrl+b "` | Horizontal split |
| `Ctrl+b z` | Zoom pane (toggle fullscreen) |
| `Ctrl+b d` | Detach session |
| `Ctrl+b [` | Copy mode |
| `Ctrl+b x` | Kill pane |
| `Ctrl+b &` | Kill window |
| `Ctrl+b Ctrl+w` | Open working notes popup (`~/work/working-notes` in Neovim) |

## Color Themes

The config includes several Nord-based color themes. Edit `~/.tmux.conf.local`:

```bash
# Blue theme (default)
tmux_conf_theme_colour_primary="#5e81ac"

# Yellow/Gold theme
tmux_conf_theme_colour_primary="#ebcb8b"

# Purple/Pink theme
tmux_conf_theme_colour_primary="#b48ead"

# Production warning - Red
tmux_conf_theme_colour_primary="#bf616a"
```

## Session Management

```bash
# New session
tmux new -s myproject

# List sessions
tmux ls

# Attach to session
tmux attach -t myproject

# Kill session
tmux kill-session -t myproject
```

## Related

- [Workspaces](./workspaces.md) - Tmux + git-worktrees integration
- [Neovim](./neovim.md) - Editor
