return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      format_notify = true,
      servers = {
        -- X will be automatically installed with mason and loaded with lspconfig
        pylsp = {
          settings = {
            pylsp = {
              plugins = {
                ruff = {
                  enabled = true,
                  extendSelect = {
                    "A", -- flake8-builtins
                    "B", -- flake8-bugbear
                    "C", -- flake8-comprehensions
                    "E", -- pycodestyle errors
                    "F", -- pyflakes
                    "I", -- isort
                    "N", -- pep8-naming
                    "RUF100",
                    "T",
                    "W", -- pycodestyle warnings
                    -- "D",  -- pydocstyle
                    -- "Q",  -- flake8-quotes
                  },
                  extendIgnore = {
                    "A002", -- Argument `id` is shadowing a Python builtin | needed for table column id
                    "A003", -- Class attribute `id` is shadowing a Python builtin | needed for table column id
                    "B008", -- function calls in argument default needed for fastapi Depends
                    "D100", -- checks for missing docstring in public modules
                    "D203", -- one blank line before class
                    "D212", -- multiline summary first line
                    "E501", -- too long line
                    "N805", -- First argument of a method should be named `self` | clashes with pydantic @validators
                    "N815", -- Variable `dependsOn` in class scope should not be mixedCase | this is done to match aws
                  },
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
        ruff_lsp = {
          -- config = "$HOME/dotfiles/.ruff.toml",
        },
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
    },
    setup = {
      ruff_lsp = function()
        require("lazyvim.util").lsp.on_attach(function(client, _)
          if client.name == "ruff_lsp" then
            client.server_capabilities.hoverProvider = false
          end
        end)
      end,
    },
  },
}
