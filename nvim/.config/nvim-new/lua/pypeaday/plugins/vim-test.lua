-- " testing
-- let test#python#runner = 'pytest'
-- let test#python#pytest#options = "--color=yes"
-- let g:ultest_use_pty = 1
--
vim.keymap.set('n', '<Leader>tn', ':TestNearest<CR>')
vim.keymap.set('n', '<Leader>tf', ':TestFile<CR>')
-- vim.keymap.set('n', '<Leader>ts', ':TestSuite<CR>')
vim.keymap.set('n', '<Leader>tl', ':TestLast<CR>')
-- vim.keymap.set('n', '<Leader>tv', ':TestVisit<CR>')
--

-- these are my keymaps from before lua transition - need to iron out with what's above
-- nmap <silent> <leader>tn <cmd>TestNearest<CR>
-- nmap <silent> <leader>tf <cmd>TestFile<CR>
-- nmap <silent> <leader>ta <cmd>TestSuite<CR>
-- nmap <silent> <leader>tl <cmd>TestLast<CR>
-- nmap <silent> <leader>tv <cmd>TestVisit<CR>

-- nnoremap <silent> <leader><leader>t <cmd>UltestNearest<cr>
-- nnoremap <silent> <leader><leader>s <cmd>UltestSummary<cr>
-- nmap ss <Plug>(ultest-output-jump) 


vim.cmd([[
    let test#python#runner = 'pytest'
    let test#python#pytest#options = "--color=yes"
    let g:ultest_use_pty = 1
]])
