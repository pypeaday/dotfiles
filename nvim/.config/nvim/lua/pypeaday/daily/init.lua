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
  local did_create = false

  if vim.tbl_isempty(files) then
    -- Create new note via copier
    os.execute("copier copy ~/dotfiles/copier/.copier_templates/daily .")

    -- Re-glob to get the new file (may need to wait a moment for creation)
    vim.wait(500, function()
      return not vim.tbl_isempty(vim.fn.glob(pattern, false, true))
    end, 10)

    files = vim.fn.glob(pattern, false, true)
    did_create = true
  end

  -- Open the note (if multiple, just pick the first)
  if not vim.tbl_isempty(files) then
    vim.cmd("edit " .. files[1])
    -- If we just created the note, insert yesterday wikilink automatically
    if did_create then
      local get_previous_daily_slug = M._get_previous_daily_slug
      if get_previous_daily_slug then
        local prev_slug = get_previous_daily_slug()
        if prev_slug then
          local wikilink = "[[ " .. prev_slug .. " ]]"
          local bufnr = vim.api.nvim_get_current_buf()
          local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          local replaced = false
          for i, line in ipairs(lines) do
            if line:match("^yesterday:%s*$") then
              lines[i] = "yesterday: " .. wikilink
              -- Ensure a blank line above and below the yesterday line
              local yidx = i
              -- Above
              if yidx == 1 or not (lines[yidx - 1] or ""):match("^%s*$") then
                table.insert(lines, yidx, "")
                yidx = yidx + 1
              end
              -- Below
              if yidx == #lines or not (lines[yidx + 1] or ""):match("^%s*$") then
                table.insert(lines, yidx + 1, "")
              end
              replaced = true
              break
            end
          end
          if not replaced then
            local insert_idx = math.min(11, #lines + 1)
            -- Insert blank line, yesterday line, then blank line
            table.insert(lines, insert_idx, "")
            table.insert(lines, insert_idx + 1, "yesterday: " .. wikilink)
            table.insert(lines, insert_idx + 2, "")
          end
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          vim.notify("Inserted yesterday link: " .. wikilink, vim.log.levels.INFO)
        end
      end
    end
  else
    print("Failed to find or create today's note.")
  end
  vim.cmd("mode")
end

-- Internal helper: get most recent previous daily note slug (not necessarily yesterday)
function M._get_previous_daily_slug()
  local daily_dir = "pages/daily"
  local today = os.date("%Y-%m-%d")

  -- Get all daily note files
  local pattern = string.format("%s/*-notes.md", daily_dir)
  local all_files = vim.fn.glob(pattern, false, true)

  if vim.tbl_isempty(all_files) then
    return nil
  end

  -- Sort files by date (newest first)
  table.sort(all_files, function(a, b)
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
    return nil
  end

  local filename = vim.fn.fnamemodify(previous_note, ":t")
  local slug = filename:match("(.+)%..+$") or filename
  return slug
end

-- Find and copy a wikilink to the most recent previous daily note
function M.copy_previous_daily_wikilink()
  local slug = M._get_previous_daily_slug()
  if not slug then
    vim.notify("No previous daily notes found", vim.log.levels.WARN)
    return
  end
  local wikilink = "[[ " .. slug .. " ]]"
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
