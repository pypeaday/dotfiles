local nnoremap = require('pypeaday.keymap_function').nnoremap
local nmap = require('pypeaday.keymap_function').nmap
local vnoremap = require('pypeaday.keymap_function').vnoremap
local inoremap = require('pypeaday.keymap_function').inoremap

vim.g.mapleader=" "
vim.g.maplocalleader=" "
-- filetype plugin indent on

-- " Be faster
vim.cmd(":command W w")
-- " Enable folding with space f
nnoremap("<leader>", "za" )

-- " navigation
-- "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
-- " Behave Vim
--
nnoremap("Y","y$" )
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

nnoremap("<c-d>","<c-d>zz")
nnoremap("<c-u","<c-u>zz")

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
nnoremap("<C-K>", "<C-W><C-K>")
nnoremap("<C-J>", "<C-W><C-J>")
nnoremap("<C-L>", "<C-W><C-L>")
nnoremap("<C-H>", "<C-W><C-H>")

-- " Python
nnoremap("<leader>ad", "<cmd>Pydocstring<CR>")

-- " fzf searching until Telescope has better grep
-- function! s:ag_with_opts(arg, bang)
--       let tokens  = split(a:arg)
--         let ag_opts = join(filter(copy(tokens), 'v:val =~ "^-"'))
--           let query   = join(filter(copy(tokens), 'v:val !~ "^-"'))
--             call fzf#vim#ag(query, ag_opts, a:bang ? {} : {'down': '100%'})
--         endfunction

--         autocmd VimEnter * command! -nargs=* -bang Ag call s:ag_with_opts(<q-args>, <bang>0)

-- nnoremap("<Leader>s", "<cmd>Ag --hidden<CR>")

-- " copy to clipbord
vnoremap("<Leader>y", ' "+y')
-- " Copy whole file to system clipboard
vnoremap("<Leader>Y", "gg'+yG")

-- " edit things
-- "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
-- " sourceconfig 
nnoremap("gsv", "<cmd>luafile ~/.config/nvim/init.lua<CR>") 

-- " source current file
nnoremap("gso", "<cmd>source %<CR>")
-- " edit nvim dotfiles
nnoremap("gek", "<cmd>e ~/.config/nvim/lua/pypeaday/keymap.lua<CR>")  
nnoremap("gel", "<cmd>e ~/.config/nvim/lua/pypeaday/plugins/lspconfig.lua<CR>")  
nnoremap("gep", "<cmd>e ~/.config/nvim/lua/pypeaday/plugins.lua<CR>")  
nnoremap("ges", "<cmd>e ~/.config/nvim/lua/pypeaday/settings.lua<CR>")  
nnoremap("geo", "<cmd>e ~/.config/nvim/lua/pypeaday/options.lua<CR>")  
nnoremap("gem", "<cmd>e ~/.config/nvim/lua/pypeaday/misc.lua<CR>")  

-- " edit tmuux config
nnoremap("get", "<cmd>e ~/.tmux.conf.local<CR>")
--(" "", " edit zshrc")
nnoremap("gez", "<cmd>e ~/.zshrc<CR>")

-- " Plug
-- "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
-- nnoremap("gpi", "<cmd>PlugInstall<CR>")
-- nnoremap(" gpc", "<cmd>PlugClean<CR>")

-- " formatting
-- "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
nnoremap("<leader>f8", "<cmd>! flake8 %<CR>")
nnoremap("<leader>fb", "<cmd>Black<CR>")

-- " LSP
-- "―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 

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
nnoremap("<leader><leader>vd", "<cmd>lua require'telegraph'.telegraph({cmd='tmux display-popup  -h 95% -w 95% -E \"visidata {cWORD}\"', how='subprocess'})<CR>")
-- " nnoremap <leader><leader>vd <cmd>lua require'telegraph'.telegraph({cmd='visidata {cWORD}', how='tmux_popup'})<CR>
--
-- might be unnecessary with neoformat
--
vim.cmd(":command Format :%!jq .")
vim.cmd(":command Unformat :%!jq -c .")
