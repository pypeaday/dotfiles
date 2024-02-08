return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      format_notify = true,
      servers = {
        docker_compose_language_service = { enabled = true },
        helm_ls = { enabled = true },
        dockerls = {},
        bashls = {},
        jsonls = {},
        html = {},
        terraformls = {},
        marksman = {},
        sqlls = {},
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
