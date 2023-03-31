return {
  "nvim-neo-tree/neo-tree.nvim",
  cmd = "Neotree",
  -- I flip LazyVim's defaults because the capital E is more inconvenient and I want the cwd tree more often
  keys = {
    {
      "<leader>fE",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").get_root() })
      end,
      desc = "Explorer NeoTree (root dir)",
    },
    {
      "<leader>fe",
      function()
        require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
      end,
      desc = "Explorer NeoTree (cwd)",
    },
    { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (cwd)", remap = true },
    -- { "<leader>tt", "<leader>fe", desc = "Explorer NeoTree (cwd)", remap = true },
    { "<leader>E", "<leader>fE", desc = "Explorer NeoTree (root dir)", remap = true },
  },
  opts = {
    filesystem = {
      bind_to_cwd = false,
      follow_current_file = true,
      filtered_items = {
        -- visible to see hidden files
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true,
      },
    },
  },
}
