-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

local function bind(op, outer_opts)
  outer_opts = outer_opts or { noremap = true }
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend("force", outer_opts, opts or {})
    map(op, lhs, rhs, opts)
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
nnoremap(
  -- " nnoremap <leader><leader>vd <cmd>lua require'telegraph'.telegraph({cmd='pipx run visidata {cWORD}', how='tmux'})<CR>
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
-- Lsp finder find the symbol definition implement reference
-- if there is no implement it will hide
-- when you use action in finder like open vsplit then you can
-- use <C-t> to jump back
map("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", { silent = true })

map("n", "<leader>gr", "<cmd>Lspsaga rename<CR>", { silent = true })
map("n", "K", "<cmd>Lspsaga hover_doc<CR>", { silent = true })

-- Peek Definition
-- you can edit the definition file in this flaotwindow
-- also support open/vsplit/etc operation check definition_action_keys
-- support tagstack C-t jump back
map("n", "<leader>pd", "<cmd>Lspsaga peek_definition<CR>", { silent = true })

-- Outline
map("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { silent = true })

-- Sorry folke but I need my gww
-- map({ "n", "x" }, "gw", "*N", { desc = "Search word under cursor" })
-- vim.keymap.del({ "n", "x" }, "gw")
