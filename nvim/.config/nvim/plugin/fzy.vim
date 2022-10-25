" function! FzyCommand(choice_command, vim_command)
"     try
"         let output = system(a:choice_command . " | fzy ")
"     catch /Vim:Interrupt/
"     " Swallow errors from ^C, allow redraw! below
"     endtry
"     redraw!
"     if v:shell_error == 0 && !empty(output)
"         exec a:vim_command . ' ' . output
"      endif
" endfunction

" nnoremap <leader>e :call FzyCommand("ag . --silent -l -g ''", ":e")<cr>
" nnoremap <leader>v :call FzyCommand("ag . --silent -l -g ''", ":vs")<cr>
" nnoremap <leader>s :call FzyCommand("ag . --silent -l -g ''", ":sp")<cr>

