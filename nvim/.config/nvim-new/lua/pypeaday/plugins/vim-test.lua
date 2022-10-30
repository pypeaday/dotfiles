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

vim.cmd([[
    let test#python#runner = 'pytest'
    let test#python#pytest#options = "--color=yes"
    let g:ultest_use_pty = 1
]])
