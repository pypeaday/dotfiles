"" -- lsp provider to find the cursor word definition and reference
"nnoremap <silent> gh <cmd>lua require'lspsaga.provider'.lsp_finder()<CR>
"" -- code action
"nnoremap <silent><leader>ca <cmd>lua require('lspsaga.codeaction').code_action()<CR>
"vnoremap <silent><leader>ca :<C-U>lua require('lspsaga.codeaction').range_code_action()<CR>
"" -- show hover doc
"nnoremap <silent> K <cmd>lua require('lspsaga.hover').render_hover_doc()<CR>

"" -- scroll down hover doc or scroll in definition preview
"nnoremap <silent> <C-g> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>
"" -- scroll up hover doc
"nnoremap <silent> <C-h> <cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>
"" -- show signature help
"nnoremap <silent> gs <cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>

"" -- rename
"nnoremap <leader>rn  <cmd>lua require('lspsaga.rename').rename()<CR>

"" -- close rename win use <C-c> in insert mode or `q` in noremal mode or `:q`
""
