if true then
  return {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        pylsp = {
          -- configurationSources = { "flake8" },
          -- enabled = { false },
          plugins = {
            ruff = {
              enabled = true,
              extendSelect = { "I" },
              extendIgnore = { "E501" },
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
    },
  }
end
-- LSP Zero not working right...
return {
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v2.x",
    dependencies = {
      -- LSP Support
      { "neovim/nvim-lspconfig" }, -- Required
      { -- Optional
        "williamboman/mason.nvim",
        -- build = function()
        --   pcall(vim.cmd, "MasonUpdate")
        -- end,
      },
      { "williamboman/mason-lspconfig.nvim" }, -- Optional

      -- Autocompletion
      { "hrsh7th/nvim-cmp" }, -- Required
      {
        "hrsh7th/cmp-nvim-lsp",
        cond = function()
          return require("lazyvim.util").has("nvim-cmp")
        end,
      }, -- Required
      { "L3MON4D3/LuaSnip" }, -- Required
    },
    config = function()
      local lsp = require("lsp-zero")

      lsp.preset("recommended")

      lsp.ensure_installed({
        "pylsp",
        "ruff_lsp",
        -- "jedi_language_server",
        "dockerls",
        "bashls",
        -- "yamlls",
        "jsonls",
        "html",
        "terraformls",
        "marksman",
      })
      -- lsp.configure("yamlls", {
      --   settings = {
      --     yaml = {
      --       enabled = false,
      --       keyOrdering = false,
      --     },
      --   },
      -- })

      lsp.configure("pylsp", {
        settings = {
          pylsp = {
            -- configurationSources = { "flake8" },
            enabled = { false },
            plugins = {
              ruff = {
                enabled = false,
                Select = { "I" },
                extendIgnore = { "E501" },
              },
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              flake8 = { enabled = false },
              mypy = {
                enabled = true,
                live_mode = true,
                strict = true,
              },
              -- jedi_completion = { fuzzy = true, enabled = true },
              -- jedi_hover = { enabled = true },
              -- jedi_references = { enabled = true },
              -- jedi_signature_help = { enabled = true },
              -- jedi_symbols = { enabled = true, all_scopes = true },
            },
          },
        },
      })
    end,
  },
}
