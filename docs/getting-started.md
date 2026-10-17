# Getting Started

## Installation

```bash
git clone https://github.com/pypeaday/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## Stow

Use [GNU Stow](https://www.gnu.org/software/stow/) to symlink configs to your home directory.

For a quick intro check out [ThePrimeagen's YT video](https://www.youtube.com/watch?v=tkUllCAGs3c)

### Available Packages

| Package | Description |
|---------|-------------|
| `nvim` | Neovim + LazyVim config |
| `tmux` | Tmux configuration |
| `zsh` | Zsh shell config |
| `starship` | Prompt configuration |
| `git` | Git config and aliases |
| `lazygit` | Lazygit TUI config |
| `fzf` | Fuzzy finder config |
| `k9s` | Kubernetes TUI config |
| `kitty` | Kitty terminal config |
| `aerospace` | macOS window manager |
| `opencode` | AI coding assistant config |
| `iron` | Work environment (GitHub Copilot) |
| `home` | Home environment (free models) |

### Basic Usage

```bash
cd ~/dotfiles

# Symlink a single package
stow nvim

# Symlink multiple packages
stow nvim tmux zsh starship git lazygit fzf

# Remove symlinks
stow -D nvim

# Restow (update symlinks)
stow -R nvim
```

### Platform-Specific Setup

#### macOS

```bash
# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install core tools
brew install neovim tmux fzf ripgrep fd lazygit starship stow

# Install window manager
brew install --cask aerospace kitty
```

#### Linux (Ubuntu/Debian)

```bash
# Install core tools
sudo apt update
sudo apt install neovim tmux fzf ripgrep fd-find stow

# Install from other sources
# lazygit: https://github.com/jesseduffield/lazygit#installation
# starship: curl -sS https://starship.rs/install.sh | sh
```

## Quick Start

```bash
# Clone and set up essential configs
git clone https://github.com/pypeaday/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow nvim tmux zsh starship git
```
