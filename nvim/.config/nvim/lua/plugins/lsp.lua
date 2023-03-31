return {
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    dependencies = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},             -- Required
      {                                      -- Optional
        'williamboman/mason.nvim',
        build = function()
          pcall(vim.cmd, 'MasonUpdate')
        end,
      },
      {'williamboman/mason-lspconfig.nvim'}, -- Optional

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},     -- Required
      {'hrsh7th/cmp-nvim-lsp'}, -- Required
      {'L3MON4D3/LuaSnip'},     -- Required
    },
    config = function()
      local lsp = require("lsp-zero")

      lsp.preset("recommended")

      lsp.ensure_installed({
          "pylsp",
          "jedi_language_server",
          "dockerls",
          "bashls",
          "yamlls",
          "jsonls",
          "html",
          "terraformls",
          "marksman",
      })

      lsp.configure("pylsp", {
          settings = {
              pylsp = {
                  -- configurationSources = { "flake8" },
                  plugins = {
                      -- pycodestyle = { enabled = false },
                      -- flake8 = { enabled = false },
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
    end
  },
  -- {
  --   "neovim/nvim-lspconfig",
  --   event = "BufReadPre",
  --   dependencies = {
  --     { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
  --     { "folke/neodev.nvim", config = true },
  --     { "j-hui/fidget.nvim", config = true },
  --     { "smjonas/inc-rename.nvim", config = true },
  --     "simrat39/rust-tools.nvim",
  --     "rust-lang/rust.vim",
  --     "williamboman/mason.nvim",
  --     "williamboman/mason-lspconfig.nvim",
  --     "hrsh7th/cmp-nvim-lsp",
  --     "hrsh7th/cmp-nvim-lsp-signature-help",
  --   },
  -- },
}
