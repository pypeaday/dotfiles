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
local cmp_sources = {
    { name = "luasnip" },
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lua' },
    { name = 'treesitter' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'tmux' },
    { name = 'spell' },
}
local lspkind = require('lspkind')
local cmp_formatting = {
    format = lspkind.cmp_format({
      mode = 'symbol', -- show only symbol annotations
      maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
      ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
    })
}
local cmp_mappings = lsp.defaults.cmp_mappings({
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
  ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
  ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  ['<C-d>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),
  ['<C-e>'] = cmp.mapping.close(),
  ['<CR>'] = cmp.mapping.confirm({
    behavior = cmp.ConfirmBehavior.Replace,
    select = true,
  })
})

-- disable completion with tab
-- this helps with copilot setup
cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil


local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line-1, 0, line-1, col, {})[1]:match("^%s*$") == nil
end

cmp.setup({
  snippet = {
    expand = function(args)
      -- For `luasnip` user.
      require('luasnip').lsp_expand(args.body)
    end,
  },
  window = {
      completion = cmp.config.window.bordered(),
  },
})

lsp.setup_nvim_cmp({
  mapping = cmp_mappings,
  sources = cmp_sources,
  formatting = cmp_formatting,
})

lsp.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = '',
        warn = '',
        hint = '',
        info = ''
    }
})


-- " nnoremap <silent> <leader>rn <cmd>lua vim.lsp.buf.rename()<CR>
nnoremap("<silent> (( ", "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>")
nnoremap("<silent> )) ", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")

nnoremap("<leader>vd", "<cmd>lua vim.lsp.buf.definition()<CR>")
nnoremap("<leader>vD", "<cmd>lua vim.lsp.buf.declaration()<CR>")
nnoremap("<leader>vh", "<cmd>lua vim.lsp.buf.hover()<CR>")
nnoremap("<leader>vi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
nnoremap("<leader>vsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>")
-- nnoremap("<leader>vrr", "<cmd>lua vim.lsp.buf.references()<CR>")
nnoremap("<leader>vrr", ":Telescope lsp_references<CR>")
nnoremap("<leader>vrn", "<cmd>lua vim.lsp.buf.rename()<CR>")
nnoremap("<leader>vca", "<cmd>lua vim.lsp.buf.code_action()<CR>")
-- " show_line_diagnostics deprecated for open_float
nnoremap("<leader>vsd", " vim.diagnostic.open_float()<CR>  ")
nnoremap("<leader>vsl", "<cmd> lua vim.diagnostic.setloclist({open=false})<CR>")
nnoremap("<leader>vn", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>")

lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
})
