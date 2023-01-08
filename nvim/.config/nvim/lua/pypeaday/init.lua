require('pypeaday.options')
require('pypeaday.keymap')
require('pypeaday.settings')
require('pypeaday.plugins')


vim.cmd([[
    augroup pypeaday
        autocmd!
        "autocmd bufwritepost .tmux.conf execute ':!tmux source-file %'
        "autocmd bufwritepost .tmux.local.conf execute ':!tmux source-file %'
        autocmd bufwritepost *.prisma execute ':! prisma validate'
        autocmd BufWritePre *.tf lua vim.lsp.buf.formatting_sync()
        autocmd TextChanged,TextChangedI *qutebrowser-editor* silent write
    augroup end
]])

function R(name)
    require("plenary.reload").reload_module(name)
end


-- remove when I switch to neotest
vim.g.ultest_deprecation_notice = 0
