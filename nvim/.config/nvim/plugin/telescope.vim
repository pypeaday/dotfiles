lua require("pypeaday")

" nnoremap gr <cmd>Telescope lsp_references<cr>
" nnoremap gd <cmd>Telescope lsp_definitions<cr>

nnoremap <leader>ps <cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input("Grep For > ")})<CR>
nnoremap <Leader>pf <cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--ignore-file', '.venv','-g' ,'!.git' }})<cr>
" nnoremap <Leader>pf <cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--ignore-file', '.venv'}})<cr>
nnoremap <Leader>pg <cmd>lua require('telescope.builtin').live_grep()<CR>
nnoremap <leader>pw <cmd>lua require('telescope.builtin').grep_string { search =  vim.fn.expand("<cword>") }<CR>
nnoremap <leader>pb <cmd>lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>ch <cmd>lua require('telescope.builtin').help_tags()<CR>

nnoremap <leader>pl <cmd>lua require('telescope.builtin').loclist()<CR>
