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
