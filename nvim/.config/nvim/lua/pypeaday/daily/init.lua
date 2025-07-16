---@diagnostic disable: undefined-global
-- vim is a global in Neovim Lua scripts
local M = {}

function M.open_now_slash()
  local file = "pages/slash/now.md"
  -- TODO
  -- open this file
  vim.cmd("edit " .. file)
end

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

-- Find and copy a wikilink to the most recent previous daily note
function M.copy_previous_daily_wikilink()
  local daily_dir = "pages/daily"
  local today = os.date("%Y-%m-%d")

  -- Get all daily note files
  local pattern = string.format("%s/*-notes.md", daily_dir)
  local all_files = vim.fn.glob(pattern, false, true)

  if vim.tbl_isempty(all_files) then
    vim.notify("No daily notes found", vim.log.levels.WARN)
    return
  end

  -- Sort files by date (newest first)
  table.sort(all_files, function(a, b)
    -- Extract dates from filenames
    local date_a = a:match("/(%d%d%d%d%-%d%d%-%d%d)")
    local date_b = b:match("/(%d%d%d%d%-%d%d%-%d%d)")

    if not date_a or not date_b then
      return false
    end

    return date_a > date_b
  end)

  -- Find the most recent note before today
  local previous_note = nil
  for _, file in ipairs(all_files) do
    local date = file:match("/(%d%d%d%d%-%d%d%-%d%d)")
    if date and date < today then
      previous_note = file
      break
    end
  end

  if not previous_note then
    vim.notify("No previous daily notes found", vim.log.levels.WARN)
    return
  end

  -- Extract the slug (filename without extension)
  local filename = vim.fn.fnamemodify(previous_note, ":t")
  local slug = filename:match("(.+)%..+$") or filename

  -- Create wikilink format
  local wikilink = "[[ " .. slug .. " ]]"

  -- Copy to system clipboard
  vim.fn.setreg("+", wikilink)
  vim.notify("Copied previous daily note link: " .. wikilink, vim.log.levels.INFO)
end

function M.find_daily_files()
  require("telescope.builtin").find_files({
    cwd = "pages/daily",
    sorting_strategy = "ascending",
  })
end

function M.find_backlinks()
  local slug = vim.fn.expand("%:t:r")
  if slug == "" then
    print("Cannot find backlinks for a file without a name.")
    return
  end

  local pattern = string.format("\\[\\[[\\s]*%s[\\s]*\\]\\]", slug)
  require("telescope.builtin").live_grep({
    default_text = pattern,
    search_dirs = { "pages" },
    prompt_title = "Backlinks for [[" .. slug .. "]]",
    additional_args = { "--pcre2" },
  })
end

-- Create user command for copying previous daily note wikilink
vim.api.nvim_create_user_command("CopyPreviousDailyLink", M.copy_previous_daily_wikilink, {})

return M
