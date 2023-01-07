local nnoremap = require('pypeaday.keymap_function').nnoremap

local on_attach = function(_, bufnr)
  vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- " nnoremap <silent> <leader>rn <cmd>lua vim.lsp.buf.rename()<CR>
    nnoremap("<silent> (( ", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
    nnoremap("<silent> )) ", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")

    nnoremap("<leader>vd", "<cmd>lua vim.lsp.buf.definition()<CR>", { buffer = bufnr })
    nnoremap("<leader>vD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { buffer = bufnr })
    nnoremap("<leader>vh", "<cmd>lua vim.lsp.buf.hover()<CR>", { buffer = bufnr })
    nnoremap("<leader>vi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { buffer = bufnr })
    nnoremap("<leader>vsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { buffer = bufnr })
    -- nnoremap("<leader>vrr", "<cmd>lua vim.lsp.buf.references()<CR>", { buffer = bufnr })
    nnoremap("<leader>vrr", ":Telescope lsp_references<CR>", { buffer = bufnr })
    nnoremap("<leader>vrn", "<cmd>lua vim.lsp.buf.rename()<CR>", { buffer = bufnr })
    nnoremap("<leader>vca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { buffer = bufnr })
    -- " show_line_diagnostics deprecated for open_float
    nnoremap("<leader>vsd", " vim.diagnostic.open_float()<CR>  ", { buffer = bufnr })
    nnoremap("<leader>vsl", "<cmd> lua vim.diagnostic.setloclist({open=false})<CR>", { buffer = bufnr })
    nnoremap("<leader>vn", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", { buffer = bufnr })
end

