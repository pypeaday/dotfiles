local nnoremap = require('pypeaday.keymap_function').nnoremap
local util = require('lspconfig.util')

vim.fn.sign_define('DiagnosticSignError', { text = '', texthl = 'DiagnosticSignError' })
vim.fn.sign_define('DiagnosticSignWarn', { text = '', texthl = 'DiagnosticSignWarn' })
vim.fn.sign_define('DiagnosticSignInfo', { text = '', texthl = 'DiagnosticSignInfo' })
vim.fn.sign_define('DiagnosticSignHint', { text = '', texthl = 'DiagnosticSignHint' })

local border = {
      {"🭽", "FloatBorder"},
      {"▔", "FloatBorder"},
      {"🭾", "FloatBorder"},
      {"▕", "FloatBorder"},
      {"🭿", "FloatBorder"},
      {"▁", "FloatBorder"},
      {"🭼", "FloatBorder"},
      {"▏", "FloatBorder"},
}

-- LSP settings (for overriding per client)
local handlers =  {
  ["textDocument/hover"] =  vim.lsp.with(vim.lsp.handlers.hover, {border = border}),
  ["textDocument/signatureHelp"] =  vim.lsp.with(vim.lsp.handlers.signature_help, {border = border }),
}

vim.diagnostic.config({
  virtual_text = false,
  severity_sort = true,
  float = {
    source = true,
    focus = false,
    format = function(diagnostic)
      if diagnostic.user_data ~= nil and diagnostic.user_data.lsp.code ~= nil then
        return string.format('%s: %s', diagnostic.user_data.lsp.code, diagnostic.message)
      end
      return diagnostic.message
    end,
  },
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

-- nvim-cmp supports additional completion capabilities
local capabilities = capabilities

require('lspconfig').bashls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

require('lspconfig').dockerls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

require('lspconfig').html.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})


require('lspconfig').jsonls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
    },
  },
})

-- require('lspconfig.configs').kedro = {
--     default_config = {
--         cmd = {"kedro-lsp"};
--         filetypes = {"python"};
--         root_dir = function(fname)
--             return vim.fn.getcwd()
--         end;
--     };
-- }

-- require'lspconfig'.kedro.setup{
--         on_attach=on_attach,
--         capabilities = capabilities,
-- }


require'lspconfig'.pylsp.setup{
        enable = true,
        capabilities = capabilities,
        handlers=handlers,
        settings = {
            pylsp = {
                configurationSources = {"flake8"},
                plugins = {
                    pycodestyle = {enabled = false},
                    flake8 = {enabled = true},
                    mypy = {
                        enabled = true,
                        live_mode =true,
                        strict = true
                    },
                    jedi_completion = {fuzzy = true, enabled=true},
                    jedi_hover = {enabled = true},
                    jedi_references = {enabled = true},
                    jedi_signature_help = {enabled = true},
                    jedi_symbols = {enabled = true, all_scopes = true},
                }
            }
        },
        on_attach = on_attach
    }

require'lspconfig'.jedi_language_server.setup{
        on_attach=on_attach,
        capabilities = capabilities,
    }

require'lspconfig'.yamlls.setup{
    on_attach=on_attach,
    handlers=handlers,
    filetypes={"yml", "yaml"},
    capabilities = capabilities,
    settings = {
        yaml = {
            format = {enable = true},
            completion = true, 
            customTags = {  -- for CloudFormation
                "!fn",
                "!Equals",
                "!And",
                "!If",
                "!Not",
                "!Equals",
                "!Or",
                "!FindInMap sequence",
                "!Base64",
                "!Cidr",
                "!Ref",
                "!Ref Scalar",
                "!Sub",
                "!GetAtt",
                "!GetAZs",
                "!ImportValue",
                "!Select",
                "!Split",
                "!Join sequence"
            },
            schemas = {
                -- ["https://raw.githubusercontent.com/quantumblacklabs/kedro/develop/static/jsonschema/kedro-catalog-0.17.json"]= "conf/**/*catalog*",
                {
                    fileMatch="/conf/**/*catalog*",
                    url="/home/u_paynen3/.caterpillar/kedro-catalog-0.17.json"
                },
                {
                    fileMatch="/.azure-pipelines/*.yaml",
                    url="/home/u_paynen3/.caterpillar/azure-pipelines-schema.json"
                },
                {
                    fileMatch="/.azure-pipelines/*.yml",
                    url="/home/u_paynen3/.caterpillar/azure-pipelines-schema.json"
                },
                -- ["/home/u_paynen3/.caterpillar/kedro-catalog-0.17.json"]= "/conf/**/*catalog*",
                -- ["https://json.schemastore.org/github-workflow.json" ]= "/.github/workflows/*",
                -- -- ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"]= "/.azure-pipelines/*.yml",
                -- ["/home/u_paynen3/.caterpillar/azure-pipelines-schema.json"]= "/.azure-pipelines/*.yml",
                -- ["https://raw.githubusercontent.com/docker/compose/master/compose/config/config_schema_v3.7.json"]= "/docker-compose.yml",

            }
        }
    }
}

require('lspconfig').texlab.setup{
    cmd = {"texlab"},
    handlers=handlers,
    filetypes = {"tex", "bib"},
    settings = {
        texlab = {
            rootDirectory = nil,
            build = _G.TeXMagicBuildConfig,
            forwardSearch = {
                executable = "evince",
                args = {"%p"}
            }
        }
    }
}
--
require('lspconfig').terraformls.setup{
    handlers=handlers,
    on_attach=on_attach,
    capabilities = capabilities,

}
