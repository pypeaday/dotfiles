local nnoremap = require('pypeaday.keymap_function').nnoremap

local lsp = require("lsp-zero")

lsp.preset("recommended")

lsp.ensure_installed({
  'pylsp',
  'jedi_language_server',
  'dockerls',
  'bashls',
  'yamlls',
  'jsonls',
  'html',
  'terraformls',
  'sumneko_lua',
})

-- Fix Undefined global 'vim'
lsp.configure('sumneko_lua', {
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' }
            }
        }
    }
})


local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = lsp.defaults.cmp_mappings({
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
})

-- disable completion with tab
-- this helps with copilot setup
cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil

lsp.setup_nvim_cmp({
  mapping = cmp_mappings
})

lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

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

lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
})
