# Zsh Configuration

## Overview

Zsh shell configuration with optimized startup, completions, and custom functions.

## Installation

```bash
cd ~/dotfiles
stow zsh
```

## Files

| File | Purpose |
|------|---------|
| `.zshrc` | Main config (sourced on interactive shells) |
| `.zprofile` | Login shell config (env vars, PATH) |
| `.zsh.completion` | Custom completion functions |

## Key Features

### Fast Startup

Completion caching reduces shell startup time. The completion dump rebuilds once per day:

```zsh
ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-${ZSH_VERSION}"
```

### Options

- `COMPLETE_IN_WORD` - Tab completion works mid-word
- Quiet shell (no beeps)

## Customization

Edit `~/.zshrc` after stowing. Common additions:

```zsh
# Aliases
alias ll='ls -la'
alias vim='nvim'

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
```

## Related

- [Starship](./starship.md) - Prompt configuration
- [FZF](../tools/fzf.md) - Fuzzy finder integration

