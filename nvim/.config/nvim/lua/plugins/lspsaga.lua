return {
  "nvimdev/lspsaga.nvim",
  enabled = true,
  -- event = "LspAttach",
  vscode = true,
  event = "LspAttach",
  config = function()
    local saga = require("lspsaga")

    saga.setup({
      lightbulb = {
        enable = false,
        enable_in_insert = false,
        sign = true,
        sign_priority = 40,
        virtual_text = true,
      },
    })
  end,
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
    --Please make sure you install markdown and markdown_inline parser
    { "nvim-treesitter/nvim-treesitter" },
  },
}
