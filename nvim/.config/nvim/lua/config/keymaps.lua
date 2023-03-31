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

local M = {}

local function bind(op, outer_opts)
  outer_opts = outer_opts or { noremap = true }
  return function(lhs, rhs, opts)
    opts = vim.tbl_extend("force", outer_opts, opts or {})
    vim.keymap.set(op, lhs, rhs, opts)
    -- vim.api.nvim_set_keymap(op, lhs, rhs, opts)
  end
end

nmap = bind("n", { noremap = false })
nnoremap = bind("n")
vnoremap = bind("v")
xnoremap = bind("x")
inoremap = bind("i")

vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- " Be faster
vim.cmd(":command W w")

-- " Behave Vim
--
nnoremap("Y", "y$")
vnoremap("<", "<gv")
vnoremap(">", ">gv")
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

-- " Jumplist
nnoremap("<expr> k", "(v:count > 5 ? 'm'' . v:count : '') . 'k' ")
nnoremap("<expr> j", "(v:count > 5 ? 'm'' . v:count : '') . 'j' ")

-- " quickfix

-- local toggleQF = vim.api.nvim_exec([[

--     let s:cisopen = 0
--     function! s:ToggleQuickFix()

--         if s:cisopen  == 1
--             let s:cisopen = 0
--             :bel copen
--             :wincmd k

--         else
--             let s:cisopen = 1
--             :cclose
--         endif
--     endfunction

--     call s:ToggleQuickFix()
--     ]],
--     true)

-- nnoremap("<Leader>qft", "<cmd>ToggleQuickFix<CR>")
-- nnoremap("<Leader>qfc", "<cmd>cexpr []<CR>")
-- nnoremap("<C-n>", "<cmd>cnext<CR>")
-- nnoremap("<C-p> ", "<cmd>cprev<CR>")

-- " Moving text
vnoremap("J", "<cmd>m '>+1<CR>gv=gv")
vnoremap("K", "<cmd>m '<-2<CR>gv=gv")
inoremap("<C-j>", "<esc><cmd>m .+1<CR>==")
inoremap("<C-k>", "<esc><cmd>m .-2<CR>==")

-- " split navigations
-- nnoremap("<C-K>", "<C-W><C-K>")
-- nnoremap("<C-J>", "<C-W><C-J>")
-- nnoremap("<C-L>", "<C-W><C-L>")
-- nnoremap("<C-H>", "<C-W><C-H>")

-- " copy to clipbord
vnoremap("<Leader>y", ' "+y')

-- " edit nvim dotfiles
nnoremap("gek", "<cmd>e ~/.config/nvim/lua/pypeaday/keymap.lua<CR>")
nnoremap("gel", "<cmd>e ~/.config/nvim/lua/pypeaday/plugins/lspconfig.lua<CR>")
nnoremap("gep", "<cmd>e ~/.config/nvim/lua/pypeaday/plugins.lua<CR>")
nnoremap("ges", "<cmd>e ~/.config/nvim/lua/pypeaday/settings.lua<CR>")
nnoremap("geo", "<cmd>e ~/.config/nvim/lua/pypeaday/options.lua<CR>")
nnoremap("gem", "<cmd>e ~/.config/nvim/lua/pypeaday/misc.lua<CR>")

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

-- " Testing things
-- "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
-- " Work
nnoremap("gec", "<cmd>e ~/.caterpillar/credentials.yml<CR>")
-- " nnoremap <leader><leader>vd <cmd>lua require'telegraph'.telegraph({cmd='pipx run visidata {cWORD}', how='tmux'})<CR>
nnoremap(
  "<leader><leader>vd",
  "<cmd>lua require'telegraph'.telegraph({cmd='tmux display-popup  -h 95% -w 95% -E \"visidata {cWORD}\"', how='subprocess'})<CR>"
)
-- " nnoremap <leader><leader>vd <cmd>lua require'telegraph'.telegraph({cmd='visidata {cWORD}', how='tmux_popup'})<CR>
--
-- might be unnecessary with neoformat
vim.cmd(":command Format :%!jq .")
vim.cmd(":command Unformat :%!jq -c .")

-- Telescope

nnoremap("gen", "<cmd>Telescope find_files cwd=~/.config/nvim <CR>")
nnoremap("<leader>ps", "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<CR>")
nnoremap(
  "<Leader>pf",
  "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--iglob', '!.venv','-g' ,'!.git' }})<cr>"
)
nnoremap("<Leader>pg", "<cmd>lua require('telescope.builtin').live_grep()<CR>")
nnoremap("<leader>pw", "<cmd>lua require('telescope.builtin').grep_string { search =  vim.fn.expand(\"<cword>\") }<CR>")
nnoremap("<leader>pb", "<cmd>lua require('telescope.builtin').buffers()<CR>")
nnoremap("<leader>pl", "<cmd>lua require('telescope.builtin').loclist()<CR>")
nnoremap("<leader>ch", "<cmd>lua require('telescope.builtin').help_tags()<CR>")

--
-- -- lsp
-- vim.keymap.set("i", "jk", "<esc>", { desc = "Exit Insert Mode with jk" })
-- vim.keymap.set(
--   "n",
--   "<silent> (( ",
--   "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>",
--   { noremap = true, desc = "Go to prev" }
-- )
-- vim.keymap.set(
--   "n",
--   "<silent> )) ",
--   "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>",
--   { noremap = true, desc = "Go to next" }
-- )
-- vim.keymap.set("n", "<leader>vd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, desc = "" })
-- vim.keymap.set("n", "<leader>vD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, desc = "" })
-- vim.keymap.set("n", "<leader>vh", "<cmd>lua vim.lsp.buf.hover()<CR>", { noremap = true, desc = "" })
-- vim.keymap.set("n", "<leader>vi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { noremap = true, desc = "" })
-- vim.keymap.set("n", "<leader>vsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap = true, desc = "" })
-- -- noremap("<leader>vrr", "<cmd>lua vim.lsp.buf.references()<CR>")
-- vim.keymap.set("n", "<leader>vrr", ":Telescope lsp_references<CR>", { noremap = true, desc = "" })
-- vim.keymap.set("n", "<leader>vrn", "<cmd>lua vim.lsp.buf.rename()<CR>", { noremap = true, desc = "" })
-- vim.keymap.set("n", "<leader>vca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { noremap = true, desc = "" })
-- -- " show_line_diagnostics deprecated for open_float
-- vim.keymap.set("n", "<leader>vsd", " vim.diagnostic.open_float()<CR>  ", { noremap = true, desc = "" })
-- vim.keymap.set(
--   "n",
--   "<leader>vsl",
--   "<cmd> lua vim.diagnostic.setloclist({open=false})<CR>",
--   { noremap = true, desc = "" }
-- )
-- vim.keymap.set("n", "<leader>vn", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", { noremap = true, desc = "" })
--
-- Ultest, Neotest, ...

nnoremap("<leader>tn", "<cmd>UltestNearest<CR>")
nnoremap("<leader>ts", "<cmd>UltestSummary<CR>")
nmap("ss", "<Plug>(ultest-output-jump)")
nnoremap("<leader>tf", "<cmd>TestFile<CR>")
nnoremap("<leader>tl", "<cmd>TestLast<CR>")
