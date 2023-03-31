-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.python3_host_prog = "~/dotfiles/.venv/nvim/bin/python"
vim.g.vim_markdown_folding_style_pythonic = { "python", "bash=sh", "json", "yaml" }
vim.g.SimpylFold_docstring_preview = 1
vim.g.indent_guides_enable_on_vim_startup = 1
vim.g.ackprg = "ag --vimgrep --hidden"
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.pydocstring_doq_path = "$HOME/.local/bin/doq"
vim.g.pydocstring_templates_path = "$HOME/dotfiles/doq/"
