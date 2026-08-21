# Neovim

I love being in the terminal, things are fast and now that we live in the future they can also be beautiful _with very little effort_

One of the best terminal apps in the whole blessed universe is [neovim](https://neovim.io/)

I right now lean heavy into [LazyVim](https://www.lazyvim.org/) from [Folke](https://github.com/folke), may his pillow case never be too hot

## Installation

```bash
cd ~/dotfiles
stow nvim
```

Config location: `~/.config/nvim/`

## Structure

```
nvim/.config/nvim/
├── init.lua        # Entry point
├── lazyvim.json    # LazyVim configuration
├── lua/            # Custom Lua config
│   ├── config/     # Options, keymaps, autocmds
│   └── plugins/    # Plugin specs
├── snippets/       # Custom snippets
└── spell/          # Spelling dictionaries
```

## Key Bindings

Leader key: `<Space>`

| Shortcut | Action |
|----------|--------|
| `<Space>ff` | Find files |
| `<Space>fg` | Live grep |
| `<Space>fb` | Browse buffers |
| `<Space>e` | File explorer (neo-tree) |
| `<Space>gg` | LazyGit |
| `<Space>xx` | Trouble diagnostics |
| `<Space>ca` | Code actions |
| `gd` | Go to definition |
| `K` | Hover documentation |

## Customization

Add plugins in `lua/plugins/`:

```lua
-- lua/plugins/example.lua
return {
  { "plugin/name", opts = {} }
}
```

## Related

- [LazyVim docs](https://www.lazyvim.org/)
- [Tmux](./tmux.md) - Terminal multiplexer
