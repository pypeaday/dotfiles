return {
  {
    "mvllow/stand.nvim",
    config = function()
      require("stand").setup({ minute_interval = 60 })
    end,
  },
}
