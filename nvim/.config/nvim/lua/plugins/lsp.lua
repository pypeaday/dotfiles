return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      format_notify = true,
      servers = {
        pylsp = {
          enabled = true,
          settings = {
            pylsp = {
              enabled = true,
              plugins = {
                ruff = {},
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
        -- X will be automatically installed with mason and loaded with lspconfig
        ruff_lsp = {},
        dockerls = {},
        bashls = {},
        sqlls = {},
        jsonls = {},
        html = {},
        terraformls = {},
        marksman = {},
      },
      setup = {},
    },
  },
}
