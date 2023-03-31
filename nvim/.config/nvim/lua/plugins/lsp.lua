return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
      { "folke/neodev.nvim", config = true },
      { "j-hui/fidget.nvim", config = true },
      { "smjonas/inc-rename.nvim", config = true },
      "simrat39/rust-tools.nvim",
      "rust-lang/rust.vim",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    config = function()
      -- you might not need lsp-zero
      require("mason").setup()

      require("mason-lspconfig").setup({
        ensure_installed = {
          -- "pylsp",
          -- "jedi_language_server",
          "ruff_lsp",
          "dockerls",
          "bashls",
          "yamlls",
          "jsonls",
          "html",
          "terraformls",
          "marksman",
          -- "rust_analyzer",
          -- "tsserver",
        },
      })

      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lsp_attach = function(client, bufnr)
      end

      local lspconfig = require("lspconfig")
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          lspconfig[server_name].setup({
            on_attach = lsp_attach,
            capabilities = lsp_capabilities,
          })
        end,
      })
    end,
  },
}
