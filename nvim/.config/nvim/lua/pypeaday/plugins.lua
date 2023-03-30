-- Install packer
local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", install_path })
    vim.cmd([[packadd packer.nvim]])
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

-- Initialize packer
require("packer").init({
  compile_path = vim.fn.stdpath("data") .. "/site/plugin/packer_compiled.lua",
  display = {
    open_fn = function()
      return require("packer.util").float({ border = "solid" })
    end,
  },
})

-- Install plugins
local use = require("packer").use

use("wbthomason/packer.nvim") -- Let packer manage itself

use("tpope/vim-commentary")
-- use('tpope/vim-repeat')
use("tpope/vim-surround")
use("tpope/vim-dispatch")
use("tpope/vim-repeat")
-- use('nelstrom/vim-visual-star-search')

use({ "catppuccin/nvim", as = "catppuccin" })

use({
  "windwp/nvim-autopairs",
  config = function()
    require("nvim-autopairs").setup()
  end,
})

use({
  "nvim-lualine/lualine.nvim",
  requires = "kyazdani42/nvim-web-devicons",
})

use({
  "kyazdani42/nvim-tree.lua",
  requires = "kyazdani42/nvim-web-devicons",
})

use({
  "rcarriga/vim-ultest",
  requires = {
    "nvim-neotest/neotest",
    "vim-test/vim-test",
  },
  run = ":UpdateRemotePlugins",
})

-- use({
--   'mgedmin/coverage-highlight.vim',
-- })

-- use({
--   'voldikss/vim-floaterm',
--   config = function()
--     require('user.plugins.floaterm')
--   end,
-- })

use({ "ThePrimeagen/harpoon" })

use({
  "nvim-telescope/telescope.nvim",
  requires = {
    { "nvim-lua/plenary.nvim" },
    { "kyazdani42/nvim-web-devicons" },
    { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
    { "nvim-telescope/telescope-live-grep-args.nvim" },
  },
})

use({
  "nvim-treesitter/nvim-treesitter",
  run = ":TSUpdate",
  requires = {
    "nvim-treesitter/playground",
    "nvim-treesitter/nvim-treesitter-textobjects",
    -- 'JoosepAlviste/nvim-ts-context-commentstring',
  },
})

-- TODO: explore this to replace my individual black, flake8, etc stuff
use({ "sbdchd/neoformat" })

use({ "wellle/targets.vim" })

use({
  "tpope/vim-fugitive",
  requires = "tpope/vim-rhubarb",
  cmd = "G",
})

use({
  "lewis6991/gitsigns.nvim",
  requires = "nvim-lua/plenary.nvim",
  config = function()
    require("gitsigns").setup({
      -- sign_priority = 20,
      -- on_attach = function(bufnr)
      --   vim.keymap.set('n', ']h', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true, buffer = bufnr })
      --   vim.keymap.set('n', '[h', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true, buffer = bufnr })
      -- end,
    })
  end,
})

use({ "onsails/lspkind.nvim" })

use({
  "VonHeikemen/lsp-zero.nvim",
  requires = {
    -- LSP Support
    { "neovim/nvim-lspconfig" },
    { "williamboman/mason.nvim" },
    { "williamboman/mason-lspconfig.nvim" },

    -- Autocompletion
    { "hrsh7th/nvim-cmp" },
    { "hrsh7th/cmp-buffer" },
    { "hrsh7th/cmp-path" },
    { "saadparwaiz1/cmp_luasnip" },
    { "hrsh7th/cmp-nvim-lsp" },
    { "hrsh7th/cmp-nvim-lua" },
    { "petertriho/cmp-git" },

    -- Snippets
    { "L3MON4D3/LuaSnip" },
    { "rafamadriz/friendly-snippets" },
  },
})

use({
  "williamboman/mason.nvim",
  "jose-elias-alvarez/null-ls.nvim",
  "jay-babu/mason-null-ls.nvim",
})

use({
  "glepnir/lspsaga.nvim",
  -- config = function()
  --   require('pypeaday.lspsaga')
  -- end,
})

use({ "itchyny/vim-gitbranch" })

use({
  "L3MON4D3/LuaSnip",
  requires = {
    "rafamadriz/friendly-snippets",
  },
})

-- LaTex
use({
  "lervag/vimtex",
})

-- Python Specific
-- settings in options.lua for now
use({
  "heavenshell/vim-pydocstring",
  run = "make install",
  ft = { "python" },
  -- config = function()
  --   local nnoremap = require('pypeaday.keymap_function').nnoremap

  --   -- for python... needs to get figured out
  --   nnoremap("<leader>ad", "<cmd>Pydocstring<CR>")
  -- end,
})

-- Experimental
use({
  "folke/which-key.nvim",
})

use({ "godlygeek/tabular" })

use({ "waylonwalker/Telegraph.nvim" })

use({ "laytan/cloak.nvim" })

use({ "APZelos/blamer.nvim" })

use({ "lfv89/vim-interestingwords" })

use({
  "amrbashir/nvim-docs-view",
  cmd = { "DocsViewToggle" },
})

-- TODO: setup neogen for python docstring generation
use({
  "danymat/neogen",
  config = function()
    require("neogen").setup({})
  end,
  requires = "nvim-treesitter/nvim-treesitter",
})

use({
  "sheerun/vim-polyglot",
})

use({
  "folke/trouble.nvim",
  requires = "kyazdani42/nvim-web-devicons",
})

-- :TZNarrow for focusing only on visual block -> useful for driving meetings
use({ "Pocco81/TrueZen.nvim" })

use({ "AndrewRadev/diffurcate.vim" })

use({
  "antoinemadec/FixCursorHold.nvim",
  config = function()
    vim.g.cursorhold_updatetime = 100
  end,
})

use({ "ThePrimeagen/vim-be-good" })

use({
  "fgheng/winbar.nvim",
  requires = {
    "SmiteshP/nvim-navic",
    "neovim/nvim-lspconfig",
    "nvim-tree/nvim-web-devicons",
  },
})

-- Like Git Graph in VS C**e
use({
  "junegunn/gv.vim",
})

use({
  "lambdalisue/suda.vim",
})

use({
  "SmiteshP/nvim-navbuddy",
  config = function()
    require("navbuddy").setup({})
  end,
  requires = {
    "neovim/nvim-lspconfig",
    "SmiteshP/nvim-navic",
    "MunifTanjim/nui.nvim",
  },
})

-- use {
--   'kkoomen/vim-doge',
--   run = ':call doge#install()'
-- }

-- Automatically install plugins on first run
if packer_bootstrap then
  require("packer").sync()
end

-- Automatically regenerate compiled loader file on save
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile>
  augroup end
]])

-- Packer
use({
  "jackMort/ChatGPT.nvim",
  config = function()
    require("chatgpt").setup({
      -- optional configuration
    })
  end,
  requires = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
})
