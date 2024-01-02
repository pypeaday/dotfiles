return {
  {
    "hrsh7th/nvim-cmp",
    version = false, -- last release is way too old
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-emoji",
    },
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      local luasnip = require("luasnip")
      local cmp = require("cmp")
      -- override nvim-cmp and add cmp-emoji
      table.insert(opts.sources, { name = "emoji" })
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
            cmp.select_next_item()
          -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
          -- this way you will only jump inside the snippet region
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          elseif has_words_before() then
            cmp.complete()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<S-CR>"] = cmp.mapping.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
      })
      -- source
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, {
        { name = "emoji" },
        { name = "nvim_lsp_signature_help", priority = 1 },
        { name = "nvim_lsp", priority = 1 },
        { name = "luasnip", priority = 2 },
        { name = "buffer", priority = 10 },
        { name = "path", priority = 4 },
        { name = "nvim_lua", priority = 5 },
        -- { name = "treesitter", priority = 2 },
        -- { name = "tmux", priority = 2 },
        { name = "spell", priority = 3 },
        { name = "git", priority = 2 },
        { name = "rg", priority = 2 },
      }))
      -- others
      -- opts.completion = cmp.config.completion(vim.list_extend(opts.completion, {
      --   completeopt = "menu,menuone,noinsert",
      -- }))
      -- opts.snippet = cmp.config.snippet(vim.list_extend(opts.snippet, {
      --   expand = function(args)
      --     require("luasnip").lsp_expand(args.body)
      --   end,
      -- }))
      -- opts.window = cmp.config.window(vim.list_extend(opts.window, {
      --   completion = cmp.config.window.bordered(),
      --   documentation = cmp.config.window.bordered(),
      -- }))
    end,
  },
  --       return {
  --         completion = {
  --           completeopt = "menu,menuone,noinsert",
  --         },
  --         snippet = {
  --           expand = function(args)
  --             require("luasnip").lsp_expand(args.body)
  --           end,
  --         },
  --         window = {
  --           completion = cmp.config.window.bordered(),
  --           documentation = cmp.config.window.bordered(),
  --         },
  --         mapping = cmp.mapping.preset.insert({
  --           -- disable completion with tab
  --           -- this helps with copilot setup
  --           -- ["<Tab>"] = nil,
  --           -- ["<S-Tab>"] = nil,
  --           ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
  --           ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
  --           ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
  --           ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  --           ["<C-b>"] = cmp.mapping.scroll_docs(-4),
  --           ["<C-d>"] = cmp.mapping.scroll_docs(-4),
  --           ["<C-f>"] = cmp.mapping.scroll_docs(4),
  --           ["<C-Space>"] = cmp.mapping.complete(),
  --           ["<C-e>"] = cmp.mapping.abort(),
  --           ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --           ["<S-CR>"] = cmp.mapping.confirm({
  --             behavior = cmp.ConfirmBehavior.Replace,
  --             select = true,
  --           }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
  --         }),
  --         sources = cmp.config.sources({
  --           { name = "nvim_lsp_signature_help", priority = 1 },
  --           { name = "nvim_lsp", priority = 1 },
  --           { name = "luasnip", priority = 2 },
  --           { name = "buffer", priority = 10 },
  --           { name = "path", priority = 4 },
  --           { name = "nvim_lua", priority = 5 },
  --           -- { name = "treesitter", priority = 2 },
  --           -- { name = "tmux", priority = 2 },
  --           { name = "spell", priority = 3 },
  --           { name = "git", priority = 2 },
  --           { name = "rg", priority = 2 },
  --         }),
  --         sorting = {
  --           priority_weight = 1.0,
  --           -- comparators = {
  --           --   cmp.config.compare.offset,
  --           --   cmp.config.compare.exact,
  --           --   cmp.config.compare.score,
  --           --   cmp.config.compare.recently_used,
  --           --   require("cmp-under-comparator").under,
  --           --   cmp.config.compare.kind,
  --           -- },
  --         },
  --         formatting = {
  --           format = function(_, item)
  --             local icons = require("lazyvim.config").icons.kinds
  --             if icons[item.kind] then
  --               item.kind = icons[item.kind] .. item.kind
  --             end
  --             return item
  --           end,
  --         },
  --         experimental = {
  --           -- ghost_text = {
  --           --   hl_group = "LspCodeLens",
  --           -- },
  --         },
  --       }
  --     end,
  --   },
}
