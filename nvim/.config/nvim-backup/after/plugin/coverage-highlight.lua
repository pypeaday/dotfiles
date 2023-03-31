-- local nnoremap = require('pypeaday.keymap_function').nnoremap
-- local noremap = require('pypeaday.keymap_function').noremap
-- noremap("[c", "<cmd><C-U>PrevUncovered<CR>") 
-- noremap("]C", "<cmd><C-U>NextUncovered<CR>")  
-- nnoremap("<leader>c", "<cmd>ToggleCoverage<CR>")  
vim.keymap.set('n', '[c', "<cmd><C-U>PrevUncovered<CR>", {noremap = false})
vim.keymap.set('n', ']c', "<cmd><C-U>NextUncovered<CR>", {noremap = false})
vim.keymap.set('n', '<leader>c', "<cmd>ToggleCoverage<CR>", {noremap = true})
