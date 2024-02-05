return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      suggestion = { enabled = true },
      panel = { enabled = true },
      filetypes = {
        markdown = true,
        help = true,
        yaml = true,
        helm = true,
        dockerfile = true,
        python = true,
        sql = true,
        lua = true,
      },
    },
  },
}
