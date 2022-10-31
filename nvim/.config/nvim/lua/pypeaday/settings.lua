--
--"           _   _   _                       _           
--"  ___  ___| |_| |_(_)_ __   __ _ _____   _(_)_ __ ___  
--" / __|/ _ \ __| __| | '_ \ / _` / __\ \ / / | '_ ` _ \ 
--" \__ \  __/ |_| |_| | | | | (_| \__ \\ V /| | | | | | |
--" |___/\___|\__|\__|_|_| |_|\__, |___(_)_/ |_|_| |_| |_|
--"                           |___/                       
--"―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
vim.cmd(":set rtp+=~/.local/share/nvim/plugged/fzf/bin/fzf")

-- General VIM
-- show line numbers
vim.cmd(":set number relativenumber")

-- vim.cmd(":set tabs to have 4 spaces
vim.cmd(":set ts=4")

-- indent when moving to the next line while writing code
vim.cmd(":set autoindent")

-- expand tabs into spaces
vim.cmd(":set expandtab")

-- when using the >> or << commands, shift lines by 4 spaces
vim.cmd(":set shiftwidth=4")

-- show a visual line under the cursor's current line
vim.cmd(":set cursorline")

-- show the matching part of the pair for [] {} and ()
vim.cmd(":set showmatch")

-- cmp
vim.cmd(":set completeopt=menu,menuone,noselect")

-- Enable folding
vim.cmd(":set foldmethod=indent")
vim.cmd(":set foldlevel=99")

vim.cmd("syntax enable")
vim.cmd(":set statusline+=%#warningmsg#")
vim.cmd(":set statusline+=%*")
vim.cmd(":set laststatus=2")
vim.cmd(":set scrolloff=30")
vim.cmd(":set nowrap")
vim.cmd(":set colorcolumn=88")
vim.cmd(":set list")
-- vim.cmd(":set listchars=tab:▸\ ,trail:·")

-- Ignore files
vim.cmd(":set wildignore+=*.pyc")
vim.cmd(":set wildignore+=*_build/*")
vim.cmd(":set wildignore+=**/coverage/*")
vim.cmd(":set wildignore+=**/.git/*")
vim.cmd(":set wildignore+=**/.venv/*")

vim.cmd(":set clipboard+=unnamedplus")

vim.cmd(":set runtimepath+=~/.config/nvim/snippets/UltiSnips/")
vim.cmd(":set runtimepath+=~/.config/nvim/snippets/")
