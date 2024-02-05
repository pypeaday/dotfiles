return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    enabled = true,
    -- Custom formatters and changes to built-in formatters
    formatters = {
      isort = {
        command = "isort",
        args = { "--sl" },
      },
      black = {
        command = "black",
        args = { "--fast" },
      },
      tidy = {
        command = "tidy-imports",
        args = { "--replace-star-imports", "--add-missing", "--replace", "--separate-from-imports", "$FILENAME" },
      },
    },

    formatters_by_ft = {
      terraform = { "terraform_fmt" },
      python = function(bufnr)
        if require("conform").get_formatter_info("ruff_format", bufnr).available then
          return { "ruff_fix", "ruff_format" }
        else
          return {}
          -- return { "isort", "black" }
        end
      end,
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pylsp = {
          enabled = false,
          settings = {
            pylsp = {
              enabled = false,
              plugins = {
                ruff = { enabled = true },
                pyflakes = { enabled = false },
                pycodestyle = { enabled = false },
                flake8 = { enabled = false },
                mypy = {
                  enabled = true,
                  live_mode = true,
                  strict = true,
                },
              },
            },
          },
        },
        pyright = { enabled = false },
        ruff_lsp = { enabled = true },
      },
    },
  },
}
