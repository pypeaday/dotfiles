
vim.cmd([[
    function! s:PyPostSave()
        execute 'silent !$HOME/.local/bin/tidy-imports --quiet --replace-star-imports --action REPLACE ' . bufname("%")
        execute 'silent !isort ' . bufname("%")
        execute 'silent !black ' . bufname("%")
        execute 'silent lua vim.diagnostic.setloclist({open=false})'
    endfunction

    ":command! PyPreSave :call s:PyPreSave()
    :command! PyPostSave :call s:PyPostSave()

    augroup pypeaday
        autocmd!
        "-- autocmd BufWritePost *.py call flake8#Flake8()
        autocmd bufwritepost *.py execute 'PyPostSave'
        autocmd bufwritepost .tmux.conf execute ':!tmux source-file %'
        autocmd bufwritepost .tmux.local.conf execute ':!tmux source-file %'
        autocmd BufWritePre *.tf lua vim.lsp.buf.formatting_sync()
        autocmd TextChanged,TextChangedI *qutebrowser-editor* silent write
    augroup end
]])
