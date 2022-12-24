
local PyPostSave = function()
    -- Get the filename of the current buffer
    local filename = vim.fn.expand("%:p")
    vim.api.nvim_command(string.format(":silent $HOME/.local/bin/tidy-imports --quiet --replace-star-imports --action REPLACE  %s", filename))
    vim.api.nvim_command(string.format(":silent isort  %s", filename))
    vim.api.nvim_command(string.format(":silent black %s", filename))
    vim.diagnostic.setloclist({open=true})
end

vim.api.nvim_command("autocmd BufWritePost *.py lua PyPostSave()")

-- vim.api.nvim_command(
--     augroup pypeaday
--         autocmd!
--         " remove trailing whitespace before python autocmd to keep newline at end of file
--         " autocmd bufwritepost * :%s/\s\+$//e
--         autocmd bufwritepost *.py execute 'lua PyPostSave()'
--         autocmd bufwritepost .tmux.conf execute ':!tmux source-file %'
--         autocmd bufwritepost .tmux.local.conf execute ':!tmux source-file %'
--         autocmd BufWritePre *.tf lua vim.lsp.buf.formatting_sync()
--         autocmd TextChanged,TextChangedI *qutebrowser-editor* silent write
--     augroup end
-- )
