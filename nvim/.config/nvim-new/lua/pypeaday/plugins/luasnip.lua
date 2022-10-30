local ls = require('luasnip')

-- require("luasnip.loaders.from_snipmate").lazy_load()

ls.config.set_config({
  history = true,
  updateevents = 'TextChanged,TextChangedI',
})
