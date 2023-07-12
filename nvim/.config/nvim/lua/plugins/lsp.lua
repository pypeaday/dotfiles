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
        -- pyright = {},
        ruff_lsp = {},
        -- jedi_language_server = {},
        dockerls = {},
        bashls = {},
        sqlls = {},
        -- yamlls = {
        --   -- Have to add this for yamlls to understand that we support line folding
        --   capabilities = {
        --     textDocument = {
        --       foldingRange = {
        --         dynamicRegistration = false,
        --         lineFoldingOnly = true,
        --       },
        --     },
        --   },
        --   -- lazy-load schemastore when needed
        --   on_new_config = function(new_config)
        --     new_config.settings.yaml.schemas = vim.tbl_deep_extend(
        --       "force",
        --       new_config.settings.yaml.schemas or {},
        --       require("schemastore").yaml.schemas()
        --     )
        --   end,
        --   settings = {
        --     redhat = { telemetry = { enabled = false } },
        --     yaml = {
        --       keyOrdering = false,
        --       format = {
        --         enable = true,
        --       },
        --       validate = true,
        --       schemaStore = {
        --         -- Must disable built-in schemaStore support to use
        --         -- schemas from SchemaStore.nvim plugin
        --         enable = false,
        --         -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
        --         url = "",
        --       },
        --       schemas = vim.list_extend(
        --         {
        --           -- DBT stuff
        --           ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/dbt_yml_files.json"] = {
        --             "/staging/**/*.yml",
        --             "/intermediate/**/*.yml",
        --             "/marts/**/*.yml",
        --             "!profiles.yml",
        --             "!dbt_project.yml",
        --             "!packages.yml",
        --             "!selectors.yml",
        --             "!profile_template.yml",
        --           },
        --           ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/dbt_project.json"] = {
        --             "dbt_project.yml",
        --           },
        --           ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/selectors.json"] = {
        --             "selectors.yml",
        --           },
        --           ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/packages.json"] = {
        --             "packages.yml",
        --           },
        --         },
        --         require("schemastore").yaml.schemas({
        --           select = {},
        --           replace = {
        --             ["GitHub Workflow"] = {
        --               name = "GitHub Workflow",
        --               description = "Avant schema for YAML GitHub Workflow",
        --               fileMatch = { "**/.github/workflows/*.y*ml" },
        --               url = "file:///Users/npayne81/dotfiles/avant/.avant-hidden-though-stowed/github-workflow.json",
        --             },
        --           },
        --         })
        --       ),
        --     },
        --   },
        -- },
        jsonls = {},
        html = {},
        terraformls = {},
        marksman = {},
      },
      setup = {
        --   yamlls = function()
        --     -- Neovim < 0.10 does not have dynamic registration for formatting
        --     if vim.fn.has("nvim-0.10") == 0 then
        --       require("lazyvim.util").lsp.on_attach(function(client, _)
        --         if client.name == "yamlls" then
        --           client.server_capabilities.documentFormattingProvider = true
        --         end
        --       end)
        --     end
        --   end,
      },
    },
  },
}
