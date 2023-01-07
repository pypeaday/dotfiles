  -- Setup nvim-cmp.
local cmp = require'cmp'
-- local lspkind = require('lspkind')

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
  mapping = {
    ['<C-n>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
    ['<C-p>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
    ['<Down>'] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
    ['<Up>'] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.close(),
    -- ['<Tab>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 's' }),
    ["<Tab>"] = vim.schedule_wrap(function(fallback)
      if cmp.visible() and has_words_before() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      else
        fallback()
      end
    end),
    ['<CR>'] = cmp.mapping.confirm({
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    })
  },
  sources = cmp.config.sources({
    { name = "copilot" },
    { name = "luasnip" },
    { name = 'nvim_lsp' },
    { name = 'nvim_lsp_signature_help' },
    { name = 'nvim_lua' },
    { name = 'treesitter' },
    { name = 'buffer' },
    { name = 'path' },
    { name = 'tmux' },
    { name = 'spell' },
    -- { name = 'cmp_tabnine' }
    }),
  -- formatting = {
  --   format = lspkind.cmp_format({with_text = false, maxwidth = 50})
  -- },
    -- formatting = {
    --         format = function(entry, vim_item)
    --             vim_item.kind = lspkind.presets.default[vim_item.kind]
    --             local menu = source_mapping[entry.source.name]
    --             if entry.source.name == 'cmp_tabnine' then
    --                 if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
    --                     menu = entry.completion_item.data.detail .. ' ' .. menu
    --                 end
    --                 vim_item.kind = ''
    --             end
    --             vim_item.menu = menu
    --             return vim_item
    --         end
    --     },
})
cmp.event:on("menu_opened", function()
  vim.b.copilot_suggestion_hidden = false
end)

cmp.event:on("menu_closed", function()
  vim.b.copilot_suggestion_hidden = false
end)

-- spelling
vim.g.opt_spell = true
vim.g.opt_spelllang = { 'en_us' }
