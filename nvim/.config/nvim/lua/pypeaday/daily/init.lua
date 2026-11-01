---@diagnostic disable: undefined-global
-- vim is a global in Neovim Lua scripts
local M = {}

local FALLBACK_ROOT = vim.fn.expand("~/projects/personal/pype.dev")

-- Resolve the site root by walking up from cwd looking for a markata config.
-- Falls back to the known repo path so daily notes work from any cwd.
local function site_root()
  local found = vim.fs.find({ "markata-go.toml", "markata.toml" }, {
    upward = true,
    path = vim.fn.getcwd(),
  })[1]
  return found and vim.fs.dirname(found) or FALLBACK_ROOT
end

M.site_root = site_root

function M.open_now_slash()
  vim.cmd.edit(site_root() .. "/pages/slash/now.md")
end

function M.check_and_open_daily_note()
  local root = site_root()
  local today = os.date("%Y-%m-%d")
  local path = string.format("%s/pages/daily/%s-notes.md", root, today)

  if vim.fn.filereadable(path) == 1 then
    vim.cmd.edit(path)
    return
  end

  -- Create via the markata-go `daily` content template (frontmatter +
  -- `yesterday:` line + sections live in markata-go.toml, not here).
  -- On checkouts without markata-go.toml (e.g. main while migrating),
  -- fall back to writing the same shape directly.
  vim.system(
    { "markata-go", "new", today .. " Notes", "-t", "daily" },
    { text = true, cwd = root },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 or vim.fn.filereadable(path) ~= 1 then
          local ok = M._write_daily_fallback(path, today)
          if not ok then
            vim.notify(
              "markata-go new failed: " .. vim.trim(result.stderr or result.stdout or ""),
              vim.log.levels.ERROR
            )
            return
          end
        end
        vim.cmd.edit(path)
        M._insert_yesterday_link()
      end)
    end
  )
end

-- Write a daily note without markata-go (mirrors the `daily` content template).
function M._write_daily_fallback(path, today)
  local ok, err = pcall(vim.fn.writefile, {
    "---",
    'title: "' .. today .. ' Notes"',
    "date: " .. today,
    "templateKey: dailyNote",
    "published: true",
    "tags:",
    "  - daily-note",
    "---",
    "",
    "yesterday:",
    "",
    "## Focus",
    "",
    "- [ ]",
    "",
    "## Notes",
    "",
    "-",
    "",
    "## Wins",
    "",
  }, path)
  return ok and err == 0
end

-- Internal helper: get most recent previous daily note slug (not necessarily yesterday)
function M._get_previous_daily_slug()
  local daily_dir = site_root() .. "/pages/daily"
  local today = os.date("%Y-%m-%d")

  -- Get all daily note files
  local all_files = vim.fn.glob(daily_dir .. "/*-notes.md", false, true)

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

-- Fill the bare `yesterday:` line in the current buffer with a wikilink to the
-- previous daily note. Falls back to inserting the line if the template lacked it.
function M._insert_yesterday_link()
  local prev_slug = M._get_previous_daily_slug()
  if not prev_slug then
    return
  end
  local wikilink = "[[ " .. prev_slug .. " ]]"
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local replaced = false
  for i, line in ipairs(lines) do
    if line:match("^yesterday:%s*$") then
      lines[i] = "yesterday: " .. wikilink
      local yidx = i
      -- Ensure a blank line above and below the yesterday line
      if yidx == 1 or not (lines[yidx - 1] or ""):match("^%s*$") then
        table.insert(lines, yidx, "")
        yidx = yidx + 1
      end
      if yidx == #lines or not (lines[yidx + 1] or ""):match("^%s*$") then
        table.insert(lines, yidx + 1, "")
      end
      replaced = true
      break
    end
  end
  if not replaced then
    local insert_idx = math.min(11, #lines + 1)
    table.insert(lines, insert_idx, "")
    table.insert(lines, insert_idx + 1, "yesterday: " .. wikilink)
    table.insert(lines, insert_idx + 2, "")
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.notify("Inserted yesterday link: " .. wikilink, vim.log.levels.INFO)
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
    cwd = site_root() .. "/pages/daily",
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
    search_dirs = { site_root() .. "/pages" },
    prompt_title = "Backlinks for [[" .. slug .. "]]",
    additional_args = { "--pcre2" },
  })
end

-- Create user command for copying previous daily note wikilink
vim.api.nvim_create_user_command("CopyPreviousDailyLink", M.copy_previous_daily_wikilink, {})

return M
