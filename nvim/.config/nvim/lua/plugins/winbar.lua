return {
  "fgheng/winbar.nvim",
  enabled = false,
  dependencies = {
    "SmiteshP/nvim-navic",
    "neovim/nvim-lspconfig",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("winbar").setup()
  end,
}
