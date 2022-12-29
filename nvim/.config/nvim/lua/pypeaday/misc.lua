
vim.cmd([[
    function! s:PyPostSave()
        execute 'silent !$HOME/.local/bin/tidy-imports --quiet --replace-star-imports --action REPLACE --separate-from-imports ' . bufname("%")
        " -lbt is --lines-between-types which defualts to 0. Change to 1 to be
        " in line with Anthony's reorder_python_imports pre-commit hook
        execute 'silent !isort -lbt 1' . bufname("%")
        execute 'silent !black ' . bufname("%")
        execute 'silent lua vim.diagnostic.setloclist({open=false})'
    endfunction

    ":command! PyPreSave :call s:PyPreSave()
    :command! PyPostSave :call s:PyPostSave()

    augroup pypeaday
        autocmd!
        " remove trailing whitespace before python autocmd to keep newline at end of file
        " autocmd bufwritepost * :%s/\s\+$//e
        "-- autocmd BufWritePost *.py call flake8#Flake8()
        autocmd bufwritepost *.py execute 'PyPostSave'
        "autocmd bufwritepost .tmux.conf execute ':!tmux source-file %'
        "autocmd bufwritepost .tmux.local.conf execute ':!tmux source-file %'
        autocmd BufWritePre *.tf lua vim.lsp.buf.formatting_sync()
        autocmd TextChanged,TextChangedI *qutebrowser-editor* silent write
    augroup end
]])
