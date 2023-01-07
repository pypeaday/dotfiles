local nnoremap = require('pypeaday.keymap_function').nnoremap
local noremap = require('pypeaday.keymap_function').noremap
noremap("[C", "<cmd><C-U>PrevUncovered<CR>") 
noremap("]C", "<cmd><C-U>NextUncovered<CR>")  
nnoremap("<leader>c", "<cmd>ToggleCoverage<CR>")  
