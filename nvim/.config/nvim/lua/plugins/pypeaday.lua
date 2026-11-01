---@diagnostic disable: undefined-global
-- vim is a global in Neovim Lua scripts
return {
  "pypeaday",
  dir = vim.fn.stdpath("config") .. "/lua/pypeaday",
  config = function()
    local daily = require("pypeaday.daily")
    local blogging = require("pypeaday.blogging")
    local copier = require("pypeaday.copier")
    local bible = require("pypeaday.bible")
    vim.api.nvim_create_user_command("DailyNote", daily.check_and_open_daily_note, {})
    vim.api.nvim_create_user_command("Daily", daily.check_and_open_daily_note, {})
    vim.api.nvim_create_user_command("BackLinks", daily.find_backlinks, {})
    vim.api.nvim_create_user_command("BlogDrafts", blogging.find_drafts, {})
    vim.api.nvim_create_user_command("Bible", function(opts)
      bible.insert_or_pick(opts.args, opts.bang)
    end, {
      nargs = "*",
      bang = true,
      complete = function(arglead, cmdline, cursorpos)
        return bible.complete_ref(arglead, cmdline, cursorpos)
      end,
      desc = "Insert an ESV passage as a scripture admonition block",
    })
    vim.keymap.set("n", "<leader>dn", daily.check_and_open_daily_note, { desc = "Open daily note" })
    vim.keymap.set("n", "<leader>df", daily.find_daily_files, { desc = "Find daily files" })
    vim.keymap.set("n", "<leader>dl", daily.find_backlinks, { desc = "Find backlinks" })
    vim.keymap.set("n", "<leader>dd", blogging.find_drafts, { desc = "Find blog drafts" })
    vim.keymap.set("n", "<leader>nn", copier.gallery, { desc = "Copier gallery" })
  end,
}
