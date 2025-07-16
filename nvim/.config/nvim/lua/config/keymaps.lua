-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

---@diagnostic disable: undefined-global
-- vim is a global in Neovim Lua scripts

-- This file contains:
-- 1. Core keymaps for basic editing and navigation
-- 2. Plugin-specific keymaps extracted from lazy specs
--    - Neo-tree (file explorer)
--    - Symbols Outline (code navigation)
--    - Telescope (fuzzy finding)
--    - Pypeaday (daily notes)
--    - Codeium (AI code completion)
--    - SuperTab/LuaSnip (snippet and completion navigation)

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap and not vim.g.vscode then
      opts.remap = nil
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

local function ToggleWordWrap()
  if vim.wo.wrap then
    vim.wo.wrap = false
    print("Word wrap disabled")
  else
    vim.wo.wrap = true
    print("Word wrap enabled")
  end
end

local function copyToClipBoard()
  vim.cmd("set clipboard+=unnamedplus")
  vim.cmd("norm! y")
  vim.cmd("set clipboard-=unnamedplus")
  print("copied!")
end

local function callVSCodeFunction(vsCodeCommand)
  vim.cmd(vsCodeCommand)
end

map("i", "<C-a>", function()
  vim.cmd("norm! ggVG")
  print("Selected all lines")
end, { remap = false, desc = "select all lines in buffer" })
map({ "v", "i" }, "<C-c>", function()
  copyToClipBoard()
end, { remap = false, desc = "copy selected text" })
-- map("i", "<C-l>", "<Del>", { remap = true, desc = "delete one character backward" })
local function neovimMappings()
  map(
    { "i", "t" },
    "<C-j>",
    "<cmd>ToggleTerm direction=float<CR><Esc>i",
    { desc = "open floating terminal", noremap = false }
  )

  map("i", "<C-f>", "<Esc>/", { noremap = false })

  -- Map a keybinding to toggle word wrap
  map("n", "<leader>ct", function()
    ToggleWordWrap()
  end, { noremap = true, silent = true, desc = "toggle word wrap" })
  map("n", "<leader>bc", "<cmd>BufferLinePick<CR>", { noremap = false, silent = true, desc = "pick buffer" })
  map("n", "-", require("oil").open, { desc = "Open parent directory" })
  -- force/replace already used keymaps
  map("n", "<leader>cs", "<cmd>AerialNavOpen<CR>", { noremap = true, silent = true, desc = "Symbols Outline(Aerial)" })
  -- my old keymaps go here I think just for nvim - so as to not be in vscode

  -- " Be faster
  map("x", "W", "w", { noremap = true })

  -- " Behave Vim
  map("n", "Y", "y$", { noremap = true })

  -- " yank text to first register then when you paste it the yanked text is still first in the register
  map("v", "<leader>p", '"0p', { noremap = true })

  -- " ESC
  map("i", "jk", "<esc>", { noremap = true })

  -- "" Keep everything centered
  map("n", "n", "nzzzv", { noremap = true })
  map("n", "N", "Nzzzv", { noremap = true })
  map("n", "J", "mzJ`z", { noremap = true })

  map("n", "<c-d>", "<c-d>zz", { noremap = true })
  map("n", "<c-u", "<c-u>zz", { noremap = true })

  -- " Undo Breakpoints
  map("i", ",", ",<c-g>u", { noremap = true })
  map("i", ".", ".<c-g>u", { noremap = true })
  map("i", "!", "!<c-g>u", { noremap = true })
  map("i", "?", "?<c-g>u", { noremap = true })
  map("i", "[", "[<c-g>u", { noremap = true })
  map("i", ";", "[<c-g>u", { noremap = true })

  -- " Jumplist
  map("n", "<expr> k", "(v:count > 5 ? 'm'' . v:count : '') . 'k' ", { noremap = true })
  map("n", "<expr> j", "(v:count > 5 ? 'm'' . v:count : '') . 'j' ", { noremap = true })

  -- " Moving text
  map("v", "J", "<cmd>m '>+1<CR>gv=gv", { noremap = true })
  map("v", "K", "<cmd>m '<-2<CR>gv=gv", { noremap = true })
  map("i", "<C-j>", "<esc><cmd>m .+1<CR>==", { noremap = true })
  map("i", "<C-k>", "<esc><cmd>m .-2<CR>==", { noremap = true })

  -- " copy to clipboard
  map("v", "<Leader>y", ' "+y', { noremap = true })

  map("n", "get", "<cmd>e ~/.tmux.conf.local<CR>", { noremap = true })
  map("n", "gez", "<cmd>e ~/.zshrc<CR>", { noremap = true })

  map("n", "<leader>x", "<cmd>!chmod +x %<CR>", { noremap = true })

  -- " Open the current file in the default program
  -- " using double leader since I kept accidentally opening things
  map("n", "<leader>o", "<cmd>!xdg-open %<cr><cr>", { noremap = false, desc = "open natively" })

  -- " Coverage navigation
  map("n", "[C", "<cmd><C-U>PrevUncovered<CR>", { noremap = true })
  map("n", "]C", "<cmd><C-U>NextUncovered<CR>", { noremap = true })
  -- map("n", "<leader>c", "<cmd>ToggleCoverage<CR>", { noremap = true })

  -- Telescope
  map("n", "gen", "<cmd>Telescope find_files cwd=~/.config/nvim <CR>", { noremap = true })
  map(
    "n",
    "<leader>ps",
    "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<CR>",
    { noremap = true }
  )
  map(
    "n",
    "<leader>pf",
    "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--iglob', '!.venv','-g' ,'!.git' }})<cr>",
    { noremap = true }
  )
  map("n", "<Leader>pg", "<cmd>lua require('telescope.builtin').live_grep()<CR>", { noremap = true })
  map(
    "n",
    "<leader>pw",
    "<cmd>lua require('telescope.builtin').grep_string { search = vim.fn.expand(\"<cword>\") }<CR>",
    { noremap = true }
  )
  map("n", "<leader>pb", "<cmd>lua require('telescope.builtin').buffers()<CR>", { noremap = true })
  map("n", "<leader>pl", "<cmd>lua require('telescope.builtin').loclist()<CR>", { noremap = true })
  map("n", "<leader>ch", "<cmd>lua require('telescope.builtin').help_tags()<CR>", { noremap = true })
end

local function vscodeMappings()
  map("n", "<C-/>", function()
    callVSCodeFunction("call VSCodeCall('workbench.action.terminal.focus')")
  end, { noremap = true, silent = true, desc = "toggle terminal" })

  map("t", "<C-l>", function()
    print("next term")
    callVSCodeFunction("call VSCodeCall('workbench.action.terminal.focusNextPane')")
  end, { noremap = true, silent = true, desc = "cycle terminal focus" })

  map("t", "<C-h>", function()
    print("prev term")
    callVSCodeFunction("call VSCodeCall('workbench.action.terminal.focusPreviousPane')")
  end, { noremap = true, silent = true, desc = "cycle terminal focus" })

  map("n", "<leader>cs", function()
    print("go to symbols in editor")
    callVSCodeFunction("call VSCodeCall('workbench.action.gotoSymbol')")
  end, { noremap = true, silent = true, desc = "go to symbols in editor" })

  map("n", "<S-l>", function()
    callVSCodeFunction("call VSCodeNotify('workbench.action.nextEditor')")
  end, { noremap = true, desc = "switch between editor to next" })

  map("n", "<S-h>", function()
    callVSCodeFunction("call VSCodeNotify('workbench.action.previousEditor')")
  end, { noremap = true, desc = "switch between editor to previous" })

  map("n", "gr", function()
    callVSCodeFunction("call VSCodeNotify('editor.action.referenceSearch.trigger')")
  end, { noremap = true, desc = "peek references inside vs code" })

  map("n", "<leader>sd", function()
    callVSCodeFunction("call VSCodeNotify('workbench.action.problems.focus')")
  end, { noremap = true, desc = "open problems and errors infos" })

  map("n", "<leader>e", function()
    callVSCodeFunction("call VSCodeNotify('workbench.files.action.focusFilesExplorer')")
  end, { noremap = true, desc = "focus to file explorer" })

  map("n", "<leader>fe", function()
    callVSCodeFunction("call VSCodeNotify('workbench.files.action.focusFilesExplorer')")
  end, { noremap = true, desc = "focus to file explorer" })

  map("n", "<leader>ff", function()
    callVSCodeFunction("call VSCodeNotify('workbench.action.quickOpen')")
  end, { noremap = true, desc = "open files" })

  map("n", "<leader>gg", function()
    callVSCodeFunction("call VSCodeNotify('workbench.view.scm')")
  end, { noremap = true, desc = "open git source control" })

  map("n", "<leader>sml", function()
    callVSCodeFunction("call VSCodeNotify('bookmarks.list')")
  end, { noremap = true, desc = "open bookmarks list for current files" })

  map("n", "<leader>smL", function()
    callVSCodeFunction("call VSCodeNotify('bookmarks.listFromAllFiles')")
  end, { noremap = true, desc = "open bookmarks list for all files" })

  map("n", "<leader>smm", function()
    callVSCodeFunction("call VSCodeNotify('bookmarks.toggle')")
  end, { noremap = true, desc = "toggle bookmarks" })

  map("n", "<leader>smd", function()
    callVSCodeFunction("call VSCodeNotify('bookmarks.clear')")
  end, { noremap = true, desc = "clear bookmarks from current file" })

  map("n", "<leader>smr", function()
    callVSCodeFunction("call VSCodeNotify('bookmarks.clearFromAllFiles')")
  end, { noremap = true, desc = "clear bookmarks from all file" })

  map("n", "<leader>cr", function()
    callVSCodeFunction("call VSCodeNotify('editor.action.rename')")
  end, { noremap = true, desc = "rename symbol" })

  map("n", "<leader>ca", function()
    callVSCodeFunction("call VSCodeNotify('editor.action.quickFix')")
  end, { noremap = true, desc = "open quick fix in vs code" })

  map("n", "<leader>cA", function()
    callVSCodeFunction("call VSCodeNotify('editor.action.sourceAction')")
  end, { noremap = true, desc = "open source Action in vs code" })

  map("n", "<leader>cp", function()
    callVSCodeFunction("call VSCodeNotify('workbench.panel.markers.view.focus')")
  end, { noremap = true, desc = "open problems diagnostics" })

  map("n", "<leader>cd", function()
    callVSCodeFunction("call VSCodeNotify('editor.action.marker.next')")
  end, { noremap = true, desc = "open problems diagnostics" })

  map({ "v" }, "<C-c>", function()
    callVSCodeFunction("call VSCodeNotify('editor.action.clipboardCopyAction')")
    print("📎added to clipboard!")
  end, { noremap = true, desc = "copy text/add text to clipboard" })
end

if vim.g.vscode then
  print("⚡connected to neovim🚀")
  vscodeMappings()
else
  neovimMappings()
end

-- ============================================================================
-- Plugin-specific keymaps (extracted from lazy specs)
-- ============================================================================

-- -----------------------------------------------------------------------------
-- Neo-tree keymaps
-- File explorer functionality
-- -----------------------------------------------------------------------------
local function setup_neotree_keymaps()
  -- Toggle file explorer in current working directory
  map("n", "<leader>fe", function()
    require("neo-tree.command").execute({ toggle = true, dir = vim.loop.cwd() })
  end, { desc = "Explorer NeoTree (cwd)" })

  -- Toggle file explorer in root directory
  map("n", "<leader>fE", function()
    require("neo-tree.command").execute({ toggle = true, dir = require("lazyvim.util").get_root() })
  end, { desc = "Explorer NeoTree (root dir)" })

  -- Alias for quick access to file explorer
  map("n", "<leader>e", "<leader>fe", { desc = "Explorer NeoTree (cwd)", remap = true })

  -- Alias for quick access to root directory explorer
  map("n", "<leader>E", "<leader>fE", { desc = "Explorer NeoTree (root dir)", remap = true })
end

-- -----------------------------------------------------------------------------
-- Symbols Outline keymaps
-- Code navigation and structure visualization
-- -----------------------------------------------------------------------------
local function setup_symbols_outline_keymaps()
  -- Open symbols outline panel
  map("n", "<leader>cs", "<cmd>SymbolsOutline<cr>", { desc = "Symbols Outline" })
end

-- -----------------------------------------------------------------------------
-- Telescope keymaps
-- Fuzzy finding and search functionality
-- -----------------------------------------------------------------------------
local function setup_telescope_keymaps()
  -- Note: Some telescope keymaps are already defined in the neovimMappings function
  -- This disables the keymap to grep files that's defined in LazyVim
  -- map("n", "<leader>/", false)

  -- Find files using Telescope
  -- map("n", "<leader>pf", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })

  -- The following keymaps are already defined in neovimMappings but are included here for reference:
  -- map("n", "<leader>ps", "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<CR>")
  -- map("n", "<leader>pf", "<cmd>lua require'telescope.builtin'.find_files()<cr>")
  -- map("n", "<Leader>pg", "<cmd>lua require('telescope.builtin').live_grep()<CR>")
  -- map("n", "<leader>pw", "<cmd>lua require('telescope.builtin').grep_string { search = vim.fn.expand("<cword>") }<CR>")
  -- map("n", "<leader>pb", "<cmd>lua require('telescope.builtin').buffers()<CR>")
  -- map("n", "<leader>pl", "<cmd>lua require('telescope.builtin').loclist()<CR>")
  -- map("n", "<leader>ch", "<cmd>lua require('telescope.builtin').help_tags()<CR>")
  -- map("n", "gen", "<cmd>Telescope find_files cwd=~/.config/nvim <CR>")
end

-- -----------------------------------------------------------------------------
-- Pypeaday keymaps
-- Daily notes and personal plugin functionality
-- -----------------------------------------------------------------------------
local function setup_pypeaday_keymaps()
  local daily = require("pypeaday.daily")

  -- Open daily note
  map("n", "<leader>dn", daily.check_and_open_daily_note, { desc = "Open daily note" })

  -- Find daily files
  map("n", "<leader>df", daily.find_daily_files, { desc = "Find daily files" })

  -- Find backlinks
  map("n", "<leader>dl", daily.find_backlinks, { desc = "Find backlinks" })

  -- Copy previous daily note wikilink
  map("n", "<leader>dy", daily.copy_previous_daily_wikilink, { desc = "Copy previous daily note wikilink" })
  -- Open now slash
  map("n", "<leader>dw", daily.open_now_slash, { desc = "Open now slash page" })
end

-- -----------------------------------------------------------------------------
-- Codeium keymaps
-- AI code completion functionality
-- -----------------------------------------------------------------------------
local function setup_codeium_keymaps()
  -- Accept suggestion
  map("i", "<C-l>", function()
    return vim.fn["codeium#Accept"]()
  end, { expr = true })

  -- Cycle to next suggestion
  map("i", "<c-;>", function()
    return vim.fn["codeium#CycleCompletions"](1)
  end, { expr = true })

  -- Cycle to previous suggestion
  map("i", "<c-,>", function()
    return vim.fn["codeium#CycleCompletions"](-1)
  end, { expr = true })

  -- Clear suggestions
  map("i", "<c-x>", function()
    return vim.fn["codeium#Clear"]()
  end, { expr = true })
end

-- -----------------------------------------------------------------------------
-- SuperTab and LuaSnip keymaps
-- Snippet and completion navigation
-- -----------------------------------------------------------------------------
local function setup_snippet_keymaps()
  -- These keymaps are implemented in the nvim-cmp configuration
  -- They're included here for documentation and organization purposes

  -- Tab key behavior:
  -- 1. If completion menu is visible: select item
  -- 2. If snippet is expandable/jumpable: expand/jump
  -- 3. If text before cursor: trigger completion
  -- 4. Otherwise: normal Tab behavior

  -- Shift-Tab key behavior:
  -- 1. If completion menu is visible: select previous item
  -- 2. If snippet is jumpable backwards: jump backwards
  -- 3. Otherwise: normal Shift-Tab behavior

  -- Note: The actual implementation is in the superTab.lua plugin config
  -- This is just for documentation purposes
end

-- Setup plugin keymaps when not in VSCode mode
if not vim.g.vscode then
  setup_neotree_keymaps()
  setup_symbols_outline_keymaps()
  setup_telescope_keymaps()
  setup_pypeaday_keymaps()
  setup_codeium_keymaps()
  setup_snippet_keymaps()
end
