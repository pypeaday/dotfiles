return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    -- disable keys for supertab
    keys = function()
      return {}
    end,
    opts = function()
      require("luasnip.loaders.from_snipmate").lazy_load({})
    end,
  },
}
