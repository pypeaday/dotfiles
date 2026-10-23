# System Requirements

## Minimum Requirements

### Operating Systems

macOS or Linux (Ubuntu, Fedora, Arch)

## Core Dependencies

These tools are required for the essential dotfiles to work:

| Tool | Purpose | macOS | Linux |
|------|---------|-------|-------|
| [stow](https://www.gnu.org/software/stow/) | Symlink manager | `brew install stow` | `apt install stow` |
| [neovim](https://neovim.io/) | Editor | `brew install neovim` | `apt install neovim` |
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer | `brew install tmux` | `apt install tmux` |
| [zsh](https://www.zsh.org/) | Shell | `brew install zsh` | `apt install zsh` |
| [git](https://git-scm.com/) | Version control | `brew install git` | `apt install git` |

## Recommended

These enhance the experience significantly:

| Tool | Purpose | macOS | Linux |
|------|---------|-------|-------|
| [starship](https://starship.rs/) | Prompt | `brew install starship` | [installer](https://starship.rs/install.sh) |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | `brew install fzf` | `apt install fzf` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast grep | `brew install ripgrep` | `apt install ripgrep` |
| [fd](https://github.com/sharkdp/fd) | Fast find | `brew install fd` | `apt install fd-find` |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI | `brew install lazygit` | [releases](https://github.com/jesseduffield/lazygit/releases) |

## Optional

| Tool | Purpose | Install |
|------|---------|---------|
| [lazydocker](https://github.com/jesseduffield/lazydocker) | Docker TUI | `brew install lazydocker` |
| [k9s](https://github.com/derailed/k9s) | Kubernetes TUI | `brew install k9s` |
| [kitty](https://sw.kovidgoyal.net/kitty/) | Terminal emulator | `brew install --cask kitty` |
| [aerospace](https://github.com/nikitabobko/AeroSpace) | macOS window manager | `brew install --cask aerospace` |

## Quick Install (macOS)

```bash
# Core
brew install stow neovim tmux zsh git

# Recommended
brew install starship fzf ripgrep fd lazygit

# Optional
brew install lazydocker k9s
brew install --cask kitty aerospace
```

## Quick Install (Ubuntu/Debian)

```bash
# Core
sudo apt update
sudo apt install stow neovim tmux zsh git

# Recommended
sudo apt install fzf ripgrep fd-find

# Starship (installer)
curl -sS https://starship.rs/install.sh | sh

# lazygit (from releases)
# See: https://github.com/jesseduffield/lazygit#installation
```

