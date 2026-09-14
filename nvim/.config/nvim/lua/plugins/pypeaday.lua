---@diagnostic disable: undefined-global
-- vim is a global in Neovim Lua scripts
return {
  "pypeaday",
  dir = vim.fn.stdpath("config") .. "/lua/pypeaday",
  config = function()
    local daily = require("pypeaday.daily")
    local blogging = require("pypeaday.blogging")
    vim.api.nvim_create_user_command("DailyNote", daily.check_and_open_daily_note, {})
    vim.api.nvim_create_user_command("Daily", daily.check_and_open_daily_note, {})
    vim.api.nvim_create_user_command("BackLinks", daily.find_backlinks, {})
    vim.api.nvim_create_user_command("BlogDrafts", blogging.find_drafts, {})
    vim.keymap.set("n", "<leader>dn", daily.check_and_open_daily_note, { desc = "Open daily note" })
    vim.keymap.set("n", "<leader>df", daily.find_daily_files, { desc = "Find daily files" })
    vim.keymap.set("n", "<leader>dl", daily.find_backlinks, { desc = "Find backlinks" })
    vim.keymap.set("n", "<leader>dd", blogging.find_drafts, { desc = "Find blog drafts" })
  end,
}
