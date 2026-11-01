# Quick Start Guide

Get up and running with the essential commands and workflows.

## Essential Commands

### Neovim

```bash
# Open neovim
nvim

# Open file
nvim filename.txt

# Key leader is <Space>
# Common commands:
# <Space>ff - Find files
# <Space>fg - Live grep
# <Space>fb - Browse buffers
# <Space>e - File explorer
# <Space>gg - LazyGit
```

### Tmux

```bash
# Start new session
tmux new -s session-name

# List sessions
tmux ls

# Attach to session
tmux attach -t session-name

# Workspaces
ws open -a

# Key prefix is Ctrl+b
# Common commands:
# Ctrl+b c - Create new window
# Ctrl+b n/p - Next/previous window
# Ctrl+b % - Split vertically
# Ctrl+b " - Split horizontally
# Ctrl+b z - Zoom pane
# Ctrl+b d - Detach from session
```

### Git with LazyGit

```bash
# Open lazygit in current repo
lazygit

# Or from neovim
# <Space>gg

# Navigation:
# j/k - Move up/down
# h/l - Move between panels
# Space - Stage/unstage
# c - Commit
# P - Push
# p - Pull
```

### Workspaces

```bash
# Create new workspace
ws new project-name

# List workspaces
ws list

# Switch workspace
ws switch project-name

# Open workspace in tmux
ws open project-name
```

## Keyboard Shortcuts Reference

### Global

| Shortcut | Action                 |
| -------- | ---------------------- |
| `Ctrl+r` | Search command history |
| `Ctrl+t` | FZF file picker        |
| `Alt+c`  | FZF directory change   |

### Neovim (Leader = Space)

| Shortcut    | Action              |
| ----------- | ------------------- |
| `<Space>ff` | Find files          |
| `<Space>fg` | Live grep           |
| `<Space>fb` | Browse buffers      |
| `<Space>e`  | File explorer       |
| `<Space>gg` | LazyGit             |
| `<Space>xx` | Trouble diagnostics |
| `<Space>ca` | Code actions        |
| `gd`        | Go to definition    |
| `K`         | Hover documentation |

### Tmux (Prefix = Ctrl+b)

| Shortcut     | Action               |
| ------------ | -------------------- |
| `Ctrl+b c`   | New window           |
| `Ctrl+b n/p` | Next/Previous window |
| `Ctrl+b %`   | Vertical split       |
| `Ctrl+b "`   | Horizontal split     |
| `Ctrl+b z`   | Zoom pane            |
| `Ctrl+b d`   | Detach session       |
| `Ctrl+b [`   | Copy mode            |

## Getting Help

Kindly RTFM or [find me somewhere](https://mydigitalharbor.com/pypeaday)

## Next Steps

- Explore [Terminal Tools](./terminal/) for detailed configurations
- Set up [Workspaces](./terminal/workspaces.md) for project management

