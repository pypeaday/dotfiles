---@diagnostic disable: undefined-global
-- Copier gallery: scaffold new content from copier templates.
-- Port of the tmux `c-b` popup (scripts/.local/bin/copier-gallery).
-- Templates embed their own `pages/<section>/` path, so `copier copy` runs
-- at the markata site root (same site_root() resolution as pypeaday.daily).

local M = {}

local function templates_dir()
  return vim.env.COPIER_GALLERY_DIR or vim.fn.expand("~/dotfiles/copier/.copier_templates")
end

local function site_root()
  return require("pypeaday.daily").site_root()
end

function M.templates()
  local dir = templates_dir()
  local ok, entries = pcall(vim.fn.readdir, dir)
  if not ok then
    return {}
  end
  return vim.tbl_filter(function(name)
    return vim.fn.isdirectory(dir .. "/" .. name) == 1
  end, entries)
end

-- Run `copier copy` for one template in a floating terminal (interactive prompts).
function M.copy(template)
  local root = site_root()
  local cmd = string.format(
    "uvx copier copy %s %s",
    vim.fn.shellescape(templates_dir() .. "/" .. template),
    vim.fn.shellescape(root)
  )
  local term = require("toggleterm.terminal").Terminal:new({
    cmd = cmd,
    dir = root,
    direction = "float",
    close_on_exit = true,
  })
  term:toggle()
  vim.schedule(function()
    vim.cmd("startinsert")
  end)
end

function M.gallery()
  local templates = M.templates()
  if #templates == 0 then
    vim.notify("No copier templates found in " .. templates_dir(), vim.log.levels.WARN)
    return
  end

  -- Telescope picker with a `tree | lolcat` preview, mirroring the tmux fzf popup.
  local ok_pickers, pickers = pcall(require, "telescope.pickers")
  if not ok_pickers then
    vim.ui.select(templates, { prompt = "copier template" }, function(choice)
      if choice then
        M.copy(choice)
      end
    end)
    return
  end
  local finders = require("telescope.finders")
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = "copier template",
      -- vertical layout with no cutoff: preview always renders, even in
      -- narrow/short herdr panes (default horizontal hides it under 120 cols
      -- and vertical hides it under 40 rows)
      layout_strategy = "vertical",
      layout_config = { preview_cutoff = 0, preview_height = 0.5 },
      finder = finders.new_table({ results = templates }),
      sorter = conf.generic_sorter({}),
      previewer = previewers.new_termopen_previewer({
        get_command = function(entry)
          return {
            "bash",
            "-c",
            "tree " .. vim.fn.shellescape(templates_dir() .. "/" .. entry.value) .. " | lolcat",
          }
        end,
      }),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            M.copy(entry.value)
          end
        end)
        return true
      end,
    })
    :find()
end

vim.api.nvim_create_user_command("CopierGallery", M.gallery, {})

return M
