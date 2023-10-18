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

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- blamer
vim.g.blamer_enabled = 1
vim.g.blamer_prefix = " > "
vim.g.blamer_show_in_visual_modes = 0
vim.g.blamer_show_in_insert_modes = 0
vim.g.blamer_delay = 500
--Available options: <author>, <author-mail>, <author-time>, <committer>, <committer-mail>, <committer-time>, <summary>, <commit-short>, <commit-long>
vim.g.blamer_template = "<committer>, <committer-time>, <summary>"
vim.g.blamer_relative_time = 0

-- ultest
vim.g.ultest_deprecation_notice = 0

vim.cmd([[
    let test#python#pytest#options = "--color=yes"
    let test#python#runner = "pytest"
]])

vim.g.ultest_use_pty = 1

-- vimtek
vim.g.vimtex_view_general_viewer = "okular"
vim.g.vimtex_view_general_options = "--unique file:@pdf#src:@line@tex"
vim.g.vimtex_view_general_options_latexmk = "--unique"

-- VimTeX uses latexmk as the default compiler backend. If you use it, which is
-- strongly recommended, you probably don't need to configure anything. If you
-- want another compiler backend, you can change it as follows. The list of
-- supported backends and further explanation is provided in the documentation,
-- see ":help vimtex-compiler".
vim.g.vimtex_compiler_method = "latexrun"
vim.g.vimtex_compiler_method = "latexmk"

-- Most VimTeX mappings rely on localleader and this can be changed with the
-- following line. The default is usually fine and is the symbol "\".
vim.maplocalleader = ","

-- tabby: self-hosted copilot alternative
-- 0.0.0.0 for alignment with docker
-- vim.g.tabby_server_url = "http://0.0.0.0:8080"
vim.g.tabby_server_url = "https://tabbyml.paynepride.com"
vim.g.tabby_accept_binding = "<C-g>"
vim.g.tabby_dismiss_binding = "<C-]>"
