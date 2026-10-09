# Starship Prompt Configuration

## Overview

[Starship](https://starship.rs/) is a minimal, blazing-fast, and customizable prompt for any shell.

## Installation

```bash
cd ~/dotfiles
stow starship
```

Config location: `~/.config/starship.toml`

## Key Features

### Prompt Symbols

```toml
[character]
success_symbol = "[❯](fg:#83DCC8)"  # Normal prompt
error_symbol = "[✗](bold red)"      # Previous command failed
```

### Git Branch

Shows current branch with purple icon:

```toml
[git_branch]
format = " [$symbol](bold purple)[$branch]($style) "
```

### AWS Profile

Displays active AWS profile and region:

```toml
[aws]
format = ' [$symbol($profile )(\($region\))]($style)'
symbol = " "
```

### Command Duration

Shows execution time for commands over 5 seconds:

```toml
[cmd_duration]
min_time = 5_000
```

### Custom Environment Variables

Displays custom env vars like `RADA_ENVIRONMENT`:

```toml
[env_var.RADA_ENVIRONMENT]
default = "dev"
format = '[  (\($env_value\))]($style)'
```

## Customization

Edit `~/.config/starship.toml`. See [Starship docs](https://starship.rs/config/) for all options.

## Related

- [Zsh](./zsh.md) - Shell configuration
