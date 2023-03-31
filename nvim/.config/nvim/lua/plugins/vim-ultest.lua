return {
  {
    "rcarriga/vim-ultest",
    dependencies = {
      "nvim-neotest/neotest",
      "vim-test/vim-test",
    },
    build = ":UpdateRemotePlugins",
  },
}
