return {
  "danymat/neogen",
  dependencies = "nvim-treesitter/nvim-treesitter",
  config = function()
    local neogen = require("neogen")
    local opts = { noremap = true, silent = true }
    vim.api.nvim_set_keymap("n", "<Leader>ad", ":lua require('neogen').generate()<CR>", opts)

    neogen.setup({
      snippet_engine = "luasnip",
      languages = {
        python = {
          template = {
            annotattion_convention = "google_docstrings",
          },
        },
      },
    })
  end,
  -- Uncomment next line if you want to follow only stable versions
  -- version = "*"
}
