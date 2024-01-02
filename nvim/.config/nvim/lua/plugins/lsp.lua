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
        -- X will be automatically installed with mason and loaded with lspconfig
        pyright = { enabled = false },
        -- enabling this doubles lsp warnings from pylsp plugin
        ruff_lsp = { enabled = true },
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
