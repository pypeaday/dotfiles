-- Install packer
local ensure_packer = function ()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

-- Initialize packer
require('packer').init({
  compile_path = vim.fn.stdpath('data')..'/site/plugin/packer_compiled.lua',
  display = {
    open_fn = function()
      return require('packer.util').float({ border = 'solid' })
    end,
  },
})

-- Install plugins
local use = require('packer').use

use('wbthomason/packer.nvim') -- Let packer manage itself

use('tpope/vim-commentary')
-- use('tpope/vim-repeat')
use('tpope/vim-surround')
use('tpope/vim-dispatch')
use('tpope/vim-repeat')
-- use('nelstrom/vim-visual-star-search')

use({
    "catppuccin/nvim",
  config = function()
    require('pypeaday.plugins.catppuccin')
  end,
})


use({
  'windwp/nvim-autopairs',
  config = function()
    require('nvim-autopairs').setup()
  end,
})


use({
  'nvim-lualine/lualine.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('pypeaday.plugins.lualine')
  end,
})


use({
  'kyazdani42/nvim-tree.lua',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('pypeaday.plugins.nvim-tree')
  end,
})

use({
  'rcarriga/vim-ultest',
  requires = {
    'nvim-neotest/neotest',
    'vim-test/vim-test',
    },
  run = ":UpdateRemotePlugins",
  config = function()
    require('pypeaday.plugins.vim-test')
  end,
})

-- use({
--   'mgedmin/coverage-highlight.vim',
--   config = function()
--     require('pypeaday.coverage-highlight')
--   end,
-- })

-- use({
--   'voldikss/vim-floaterm',
--   config = function()
--     require('user.plugins.floaterm')
--   end,
-- })

use({ 'ThePrimeagen/harpoon' })

use({
  'nvim-telescope/telescope.nvim',
  requires = {
    { 'nvim-lua/plenary.nvim' },
    { 'kyazdani42/nvim-web-devicons' },
    { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' },
    { 'nvim-telescope/telescope-live-grep-args.nvim' },
  },
  config = function()
    require('pypeaday.plugins.telescope')
  end,
})

use({
  'nvim-treesitter/nvim-treesitter',
  run = ":TSUpdate",
  requires = {
    'nvim-treesitter/playground',
    'nvim-treesitter/nvim-treesitter-textobjects',
    -- 'JoosepAlviste/nvim-ts-context-commentstring',
  },
  config = function()
    require('pypeaday.plugins.treesitter')
  end,
})

-- TODO: explore this to replace my individual black, flake8, etc stuff
use({ 'sbdchd/neoformat', })

use({'wellle/targets.vim'})

use({
  'tpope/vim-fugitive',
  requires = 'tpope/vim-rhubarb',
  cmd = 'G',
})

use({
  'lewis6991/gitsigns.nvim',
  requires = 'nvim-lua/plenary.nvim',
  config = function()
    require('gitsigns').setup({
      -- sign_priority = 20,
      -- on_attach = function(bufnr)
      --   vim.keymap.set('n', ']h', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true, buffer = bufnr })
      --   vim.keymap.set('n', '[h', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true, buffer = bufnr })
      -- end,
    })
  end,
})

use({
  'neovim/nvim-lspconfig',
  requires = {
    'b0o/schemastore.nvim',
    -- 'nvim-lua/lsp_extensions.nvim',
    'folke/lsp-colors.nvim',
  },
  config = function()
    require('pypeaday.plugins.lspconfig')
  end,
})

use({
  'glepnir/lspsaga.nvim',
  config = function()
    require('pypeaday.plugins.lspsaga')
  end,
})

use({'itchyny/vim-gitbranch'})


use({
  'L3MON4D3/LuaSnip',
  requires = {
    "rafamadriz/friendly-snippets",
  },
  config = function()
    require('pypeaday.plugins.luasnip')
  end,
})

use({
  'hrsh7th/nvim-cmp',
  requires = {
    -- 'SirVer/ultisnips',
    -- 'quangnguyen30192/cmp-nvim-ultisnips',
    -- 'honza/vim-snippets',
    {
      'L3MON4D3/LuaSnip',
      event = "BufReadPre",
      wants = "friendly-snippets",
      requires = {
        "rafamadriz/friendly-snippets",
      },
      config = function()
        require('pypeaday.plugins.luasnip')
      end,
    },
    {'hrsh7th/cmp-buffer'},
    {'hrsh7th/cmp-path'},
    {'hrsh7th/cmp-cmdline'},
    {'hrsh7th/cmp-nvim-lsp'},
    {'hrsh7th/cmp-nvim-lsp-signature-help'},
    {'hrsh7th/cmp-nvim-lua'},
    {'onsails/lspkind-nvim'},
    {'f3fora/cmp-spell'},
    {'saadparwaiz1/cmp_luasnip'},
  },
  wants = { "LuaSnip"},
  config = function()
    require('pypeaday.plugins.cmp')
  end,
})


-- LaTex
use ({
    'lervag/vimtex',
    config = function()
        require('pypeaday.plugins.vimtex')
    end,
})

-- Python Specific
-- settings in options.lua for now
use ({
    'heavenshell/vim-pydocstring',
    run = 'make install',
    ft = {'python'},
    -- config = function()
    --   local nnoremap = require('pypeaday.keymap_function').nnoremap

    --   -- for python... needs to get figured out
    --   nnoremap("<leader>ad", "<cmd>Pydocstring<CR>")
    -- end,
})

-- Experimental

use({'godlygeek/tabular'})

use({'waylonwalker/Telegraph.nvim'})

use({'laytan/cloak.nvim'})

use({'APZelos/blamer.nvim'})

use({'lfv89/vim-interestingwords'})

use({
    'amrbashir/nvim-docs-view', 
    cmd={'DocsViewToggle'},
})

-- TODO: setup neogen for python docstring generation
use({
  'danymat/neogen',
  config = function()
    require('neogen').setup({})
  end,
  requires = 'nvim-treesitter/nvim-treesitter',
})

use({
  'sheerun/vim-polyglot',
})

use({
  'folke/trouble.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('pypeaday.plugins.trouble')
  end,
})

-- :TZNarrow for focusing only on visual block -> useful for driving meetings
use({'Pocco81/TrueZen.nvim'})

use({'AndrewRadev/diffurcate.vim'})

use({
  'antoinemadec/FixCursorHold.nvim',
  config = function()
    vim.g.cursorhold_updatetime = 100
  end,
})

use({'ThePrimeagen/vim-be-good'})

-- use({ 
--   'fgheng/winbar.nvim',
--   config = function()
--     require('pypeaday.plugins.winbar')
--   end,
--   requires = {
--     "SmiteshP/nvim-navic",
--     "neovim/nvim-lspconfig",
--     "nvim-tree/nvim-web-devicons"
--   },
-- }) 
use {
  'lambdalisue/suda.vim'
}

-- Automatically install plugins on first run
if packer_bootstrap then
  require('packer').sync()
end

-- Automatically regenerate compiled loader file on save
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile>
  augroup end
]])
