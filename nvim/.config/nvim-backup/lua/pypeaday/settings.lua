--
--"           _   _   _                       _           
--"  ___  ___| |_| |_(_)_ __   __ _ _____   _(_)_ __ ___  
--" / __|/ _ \ __| __| | '_ \ / _` / __\ \ / / | '_ ` _ \ 
--" \__ \  __/ |_| |_| | | | | (_| \__ \\ V /| | | | | | |
--" |___/\___|\__|\__|_|_| |_|\__, |___(_)_/ |_|_| |_| |_|
--"                           |___/                       
--"―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
vim.opt.rtp:append("~/.local/share/nvim/plugged/fzf/bin/fzf")

-- General VIM
-- show line numbers
vim.opt.relativenumber = true

-- vim.cmd(":set tabs to have 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- indent when moving to the next line while writing code
vim.opt.autoindent = true

-- show a visual line under the cursor's current line
vim.opt.cursorline = true

-- show the matching part of the pair for [] {} and ()
vim.opt.showmatch = true

-- cmp
vim.opt.completeopt = "menu,menuone,noselect"

-- Enable folding
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99

vim.opt.syntax = "yes"
vim.opt.statusline:append("%#warningmsg#")
vim.opt.statusline:append("%*")
vim.opt.laststatus = 2
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.colorcolumn = "88"
vim.opt.list = true

-- Ignore files
vim.opt.wildignore:append("*.pyc")
vim.opt.wildignore:append("*_build/*")
vim.opt.wildignore:append("**/coverage/*")
vim.opt.wildignore:append("**/.git/*")
vim.opt.wildignore:append("**/.venv/*")
vim.opt.clipboard:append("unnamedplus")
