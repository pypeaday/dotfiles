return {

  "glepnir/lspsaga.nvim",
  event = "LspAttach",
  config = function()
    local saga = require("lspsaga")

    saga.setup({})
  end,
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
    --Please make sure you install markdown and markdown_inline parser
    { "nvim-treesitter/nvim-treesitter" },
  },
}
