return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      format_notify = true,
      servers = {
        pylsp = {
          settings = {
            pylsp = {
              -- configurationSources = { "flake8" },
              --   -- enabled = { false },
              plugins = {
                ruff = {
                  enabled = true,
                  extendSelect = {
                    "I",
                    "A",
                    "B",
                    "C",
                    "E",
                    "F",
                    "I",
                    "N",
                    "RUF100",
                    "T",
                    "W",
                  },
                  extendIgnore = { "E501" },
                  lineLength = 120,
                },
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
        -- pyright = {},
        ruff_lsp = {},
        -- jedi_language_server = {},
        dockerls = {},
        bashls = {},
        yamlls = {
          settings = {
            yamlVersion = 1.2,
            keyOrdering = false,
            validate = false,
          },
          -- enabled = { false },
          schemas = {
            ["https://raw.githubusercontent.com/quantumblacklabs/kedro/develop/static/jsonschema/kedro-catalog-0.17.json"] = "conf/**/*catalog*",
            ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
            ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
              "/azure-pipeline*.y*l",
              "/*.azure*",
              "Azure-Pipelines/**/*.y*l",
              "Pipelines/*.y*l",
            },
          },
        },
        jsonls = {},
        html = {},
        terraformls = {},
        marksman = {},
      },
      setup = {},
    },
  },
}
