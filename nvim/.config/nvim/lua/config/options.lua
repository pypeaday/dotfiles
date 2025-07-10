-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.lazyvim_picker = "fzf"
-- LSP Server to use for Python.
-- Set to "basedpyright" to use basedpyright instead of pyright.
vim.g.lazyvim_python_lsp = "pyright"
-- Set to "ruff_lsp" to use the old LSP implementation version.
vim.g.lazyvim_python_ruff = "ruff"
-- vim.g.python3_host_prog = "~/dotfiles/.venv/dotfiles/bin/python"
-- vim.g.vim_markdown_folding_style_pythonic = { "python", "bash=sh", "json", "yaml" }
-- vim.g.SimpylFold_docstring_preview = 1
-- vim.g.indent_guides_enable_on_vim_startup = 1
vim.g.ackprg = "ag --vimgrep --hidden"
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- blamer
vim.g.blamer_enabled = 1
vim.g.blamer_prefix = " > "
vim.g.blamer_show_in_visual_modes = 0
vim.g.blamer_show_in_insert_modes = 0
vim.g.blamer_delay = 500
-- Available options: <author>, <author-mail>, <author-time>, <committer>, <committer-mail>, <committer-time>, <summary>, <commit-short>, <commit-long>
vim.g.blamer_template = "<committer>, <committer-time>, <summary>"
vim.g.blamer_relative_time = 0

---
-- Dependencies: os.date, vim.fn, vim.cmd

local M = {}

function M.check_and_open_daily_note()
  local daily_dir = "pages/daily"
  local today = os.date("%Y-%m-%d")
  local pattern = string.format("%s/%s*-notes.md", daily_dir, today)
  -- Check if today's note exists
  local files = vim.fn.glob(pattern, false, true)

  if vim.tbl_isempty(files) then
    -- Create new note via copier
    os.execute("copier copy ~/dotfiles/copier/.copier_templates/daily .")

    -- Re-glob to get the new file (may need to wait a moment for creation)
    vim.wait(500, function()
      return not vim.tbl_isempty(vim.fn.glob(pattern, false, true))
    end, 10)

    files = vim.fn.glob(pattern, false, true)
  end

  -- Open the note (if multiple, just pick the first)
  if not vim.tbl_isempty(files) then
    vim.cmd("edit " .. files[1])
  else
    print("Failed to find or create today's note.")
  end
  vim.cmd("mode")
end

vim.api.nvim_create_user_command("DailyNote", function()
  M.check_and_open_daily_note()
end, {})

vim.api.nvim_create_user_command("Daily", function()
  M.check_and_open_daily_note()
end, {})

vim.api.nvim_create_user_command("DailyFiles", function()
  require("telescope.builtin").find_files({
    cwd = "pages/daily",
    sorting_strategy = "ascending",
  })
end, {})

vim.keymap.set("n", "<leader>dn", M.check_and_open_daily_note)
vim.keymap.set("n", "<leader>df", function()
  require("telescope.builtin").find_files({
    cwd = "pages/daily",
    sorting_strategy = "ascending",
  })
end)

return M
