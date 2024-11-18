-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.lazyvim_picker = "fzf"
-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "pyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"
-- vim.g.python3_host_prog = "~/dotfiles/.venv/dotfiles/bin/python"
-- vim.g.vim_markdown_folding_style_pythonic = { "python", "bash=sh", "json", "yaml" }
-- vim.g.SimpylFold_docstring_preview = 1
-- vim.g.indent_guides_enable_on_vim_startup = 1
vim.g.ackprg = "ag --vimgrep --hidden"
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- blamer
vim.g.blamer_enabled = 1
vim.g.blamer_prefix = " > "
vim.g.blamer_show_in_visual_modes = 0
vim.g.blamer_show_in_insert_modes = 0
vim.g.blamer_delay = 500
-- Available options: <author>, <author-mail>, <author-time>, <committer>, <committer-mail>, <committer-time>, <summary>, <commit-short>, <commit-long>
vim.g.blamer_template = "<committer>, <committer-time>, <summary>"
vim.g.blamer_relative_time = 0
