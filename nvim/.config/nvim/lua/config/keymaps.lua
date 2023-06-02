-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local Util = require("lazyvim.util")

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

local function bind(op, outer_opts)
  outer_opts = outer_opts or { noremap = true }
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend("force", outer_opts, opts or {})
    vim.keymap.set(op, lhs, rhs, opts)
    -- vim.api.nvim_set_keymap(op, lhs, rhs, opts)
  end
end

local nmap = bind("n", { noremap = false })
local nnoremap = bind("n")
local vnoremap = bind("v")
local xnoremap = bind("x")
local inoremap = bind("i")

-- " Be faster
xnoremap("W", "w")

-- " Behave Vim
--
nnoremap("Y", "y$")

-- " yank text to first regiter then when you paste it the yanked text is still first in the register
-- " vnoremap <Leader>p "_P
vnoremap("<leader>p", '"0p')

-- " ESC
inoremap("jk", "<esc>")

-- "" Keep everything centered
nnoremap("n", "nzzzv")
nnoremap("N", "Nzzzv")
nnoremap("J", "mzJ`z")

nnoremap("<c-d>", "<c-d>zz")
nnoremap("<c-u", "<c-u>zz")

-- " Undo Breakpoints
inoremap(",", ",<c-g>u")
inoremap(".", ".<c-g>u")
inoremap("!", "!<c-g>u")
inoremap("?", "?<c-g>u")
inoremap("[", "[<c-g>u")
inoremap(";", "[<c-g>u")

-- " Jumplist
nnoremap("<expr> k", "(v:count > 5 ? 'm'' . v:count : '') . 'k' ")
nnoremap("<expr> j", "(v:count > 5 ? 'm'' . v:count : '') . 'j' ")

-- " Moving text
vnoremap("J", "<cmd>m '>+1<CR>gv=gv")
vnoremap("K", "<cmd>m '<-2<CR>gv=gv")
inoremap("<C-j>", "<esc><cmd>m .+1<CR>==")
inoremap("<C-k>", "<esc><cmd>m .-2<CR>==")

-- " copy to clipbord
vnoremap("<Leader>y", ' "+y')

nnoremap("get", "<cmd>e ~/.tmux.conf.local<CR>")
nnoremap("gez", "<cmd>e ~/.zshrc<CR>")

nnoremap("<leader>x", "<cmd>!chmod +x %<CR>")

-- " Open the current file in the default program
-- " using double leader since I kept accidently opening things
nmap("<leader><leader>o", "<cmd>!xdg-open %<cr><cr>")

-- " Coverage navigation
nnoremap("[C", "<cmd><C-U>PrevUncovered<CR>")
nnoremap("]C", "<cmd><C-U>NextUncovered<CR>")
nnoremap("<leader>c", "<cmd>ToggleCoverage<CR>")

-- " Work
nnoremap("gec", "<cmd>e ~/.caterpillar/credentials.yml<CR>")
-- " nnoremap <leader><leader>vd <cmd>lua require'telegraph'.telegraph({cmd='pipx run visidata {cWORD}', how='tmux'})<CR>
nnoremap(
  "<leader><leader>vd",
  "<cmd>lua require'telegraph'.telegraph({cmd='tmux display-popup  -h 95% -w 95% -E \"visidata {cWORD}\"', how='subprocess'})<CR>"
)
-- " nnoremap <leader><leader>vd <cmd>lua require'telegraph'.telegraph({cmd='visidata {cWORD}', how='tmux_popup'})<CR>
--

-- Telescope

nnoremap("gen", "<cmd>Telescope find_files cwd=~/.config/nvim <CR>")
nnoremap("<leader>ps", "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<CR>")
nnoremap(
  "<Leader>pf",
  "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--iglob', '!.venv','-g' ,'!.git' }})<cr>"
  -- "<cmd>lua require'telescope.builtin'.find_files()<cr>"
)
nnoremap("<Leader>pg", "<cmd>lua require('telescope.builtin').live_grep()<CR>")
nnoremap("<leader>pw", "<cmd>lua require('telescope.builtin').grep_string { search =  vim.fn.expand(\"<cword>\") }<CR>")
nnoremap("<leader>pb", "<cmd>lua require('telescope.builtin').buffers()<CR>")
nnoremap("<leader>pl", "<cmd>lua require('telescope.builtin').loclist()<CR>")
nnoremap("<leader>ch", "<cmd>lua require('telescope.builtin').help_tags()<CR>")

-- Ultest, Neotest, ...

nnoremap("<leader>tn", "<cmd>UltestNearest<CR>")
nnoremap("<leader>ts", "<cmd>UltestSummary<CR>")
nmap("ss", "<Plug>(ultest-output-jump)")
nnoremap("<leader>tf", "<cmd>TestFile<CR>")
nnoremap("<leader>tl", "<cmd>TestLast<CR>")

-- LspSaga
-- I use Lspsaga mainly for the outline and peek definition. I replace hover since it's nicer
local keymap = vim.keymap.set
-- Lsp finder find the symbol definition implement reference
-- if there is no implement it will hide
-- when you use action in finder like open vsplit then you can
-- use <C-t> to jump back
keymap("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", { silent = true })

keymap("n", "<leader>gr", "<cmd>Lspsaga rename<CR>", { silent = true })
keymap("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true })

-- Peek Definition
-- you can edit the definition file in this flaotwindow
-- also support open/vsplit/etc operation check definition_action_keys
-- support tagstack C-t jump back
keymap("n", "<leader>pd", "<cmd>Lspsaga peek_definition<CR>", { silent = true })

-- Outline
keymap("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { silent = true })

-- These settings are LazyVim default but I just hate the gw remap so I disable loading Folke's and I just copy the rest of his default keymaps here
-- better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
-- map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
-- map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
-- map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
-- map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
-- map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
-- map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- buffers
if Util.has("bufferline.nvim") then
  map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
  map("n", "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
  map("n", "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
else
  map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
  map("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
  map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
end
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>`", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Clear search, diff update and redraw
-- taken from runtime/lua/_editor.lua
map(
  "n",
  "<leader>ur",
  "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
  { desc = "Redraw / clear hlsearch / diff update" }
)

-- Sorry folke but I need my gww
-- map({ "n", "x" }, "gw", "*N", { desc = "Search word under cursor" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- save file
map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Lazy" })

-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Location List" })
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Quickfix List" })

if not Util.has("trouble.nvim") then
  map("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" })
  map("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" })
end

-- stylua: ignore start

-- toggle options
map("n", "<leader>uf", require("lazyvim.plugins.lsp.format").toggle, { desc = "Toggle format on Save" })
map("n", "<leader>us", function() Util.toggle("spell") end, { desc = "Toggle Spelling" })
map("n", "<leader>uw", function() Util.toggle("wrap") end, { desc = "Toggle Word Wrap" })
map("n", "<leader>ul", function() Util.toggle("relativenumber", true) Util.toggle("number") end, { desc = "Toggle Line Numbers" })
map("n", "<leader>ud", Util.toggle_diagnostics, { desc = "Toggle Diagnostics" })
local conceallevel = vim.o.conceallevel > 0 and vim.o.conceallevel or 3
map("n", "<leader>uc", function() Util.toggle("conceallevel", false, {0, conceallevel}) end, { desc = "Toggle Conceal" })

-- lazygit
map("n", "<leader>gg", function() Util.float_term({ "lazygit" }, { cwd = Util.get_root() }) end, { desc = "Lazygit (root dir)" })
map("n", "<leader>gG", function() Util.float_term({ "lazygit" }) end, { desc = "Lazygit (cwd)" })

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- highlights under cursor
if vim.fn.has("nvim-0.9.0") == 1 then
  map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
end

-- floating terminal
map("n", "<leader>ft", function() Util.float_term(nil, { cwd = Util.get_root() }) end, { desc = "Terminal (root dir)" })
map("n", "<leader>fT", function() Util.float_term() end, { desc = "Terminal (cwd)" })
map("t", "<esc><esc>", "<c-\\><c-n>", {desc = "Enter Normal Mode"})

-- windows
map("n", "<leader>ww", "<C-W>p", { desc = "Other window" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
map("n", "<leader>w-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>w|", "<C-W>v", { desc = "Split window right" })
map("n", "<leader>-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right" })

-- tabs
map("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
map("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
