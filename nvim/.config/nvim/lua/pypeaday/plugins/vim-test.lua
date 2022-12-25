local nnoremap = require('pypeaday.keymap_function').nnoremap
local nmap = require('pypeaday.keymap_function').nmap
vim.cmd([[
    let test#python#runner = 'pytest'
    let test#python#pytest#options = "--color=yes"
    let g:ultest_use_pty = 1
]])

-- nnoremap('<leader>tn', '<cmd>TestNearest<CR>')
nnoremap('<leader>tn', '<cmd>UltestNearest<CR>')
nnoremap('<leader>ts', '<cmd>UltestSummary<CR>')
nmap('ss', '<Plug>(ultest-output-jump)')
nnoremap('<leader>tf', '<cmd>TestFile<CR>')
nnoremap('<leader>tl', '<cmd>TestLast<CR>')

