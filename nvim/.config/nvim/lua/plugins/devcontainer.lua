return {
  "https://codeberg.org/esensar/nvim-dev-container",
  dependencies = "nvim-treesitter/nvim-treesitter",
  -- TODO: the docker override isn't working, can try it at work
  opts = {
    config = function()
      require("devcontainer").setup({
        container_runtime = "docker",
      })
    end,
  },
}
