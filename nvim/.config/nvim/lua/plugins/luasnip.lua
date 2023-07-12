return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = function()
      require("luasnip.loaders.from_snipmate").lazy_load({})
    end,
  },
}
