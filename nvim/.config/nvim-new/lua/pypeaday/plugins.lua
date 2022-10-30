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

-- use({
--   'airblade/vim-rooter',
--   setup = function()
--     vim.g.rooter_manual_only = 1
--   end,
--   config = function()
--     vim.cmd('Rooter')
--   end,
-- })
-- use('christoomey/vim-tmux-navigator')
-- use('farmergreg/vim-lastplace')
use('tpope/vim-commentary')
-- use('tpope/vim-repeat')
use('tpope/vim-surround')
use('tpope/vim-dispatch')
use('tpope/vim-repeat')
-- use('tpope/vim-eunuch') -- Adds :Rename, :SudoWrite
-- use('tpope/vim-unimpaired') -- Adds [b and other handy mappings
-- use('tpope/vim-sleuth') -- Indent autodetection with editorconfig support
-- use('jessarcher/vim-heritage') -- Automatically create parent dirs when saving
-- use('nelstrom/vim-visual-star-search')
-- use { 'posva/vim-vue' }

-- use({
--   'tpope/vim-projectionist',
--   requires = 'tpope/vim-dispatch',
--   config = function()
--     require('user.plugins.projectionist')
--   end,
-- })
--
use({
    'jim-at-jibba/ariake-vim-colors',
    config = function()
        vim.cmd("set termguicolors")
        vim.cmd("colorscheme ariake")
        -- Transparency
        vim.cmd[[hi Normal guibg=NONE ctermbg=NONE]]
        vim.cmd[[hi clear Comment]]  -- comments had big blocks like visual selection - turn it off
        vim.cmd[[hi Comment ctermbg=NONE guifg=gray ctermfg=gray]] -- need to set fg for comments after turning off the weird highlights
        vim.cmd[[hi clear Function]]  -- Had annoying function highlighting in python
        vim.cmd[[hi LineNR guibg=None guifg=gray ctermfg=gray]]
        vim.cmd[[hi clear SignColumn ]]
        vim.cmd[[hi ColorColumn ctermbg=darkgrey guibg=darkgrey]]
        -- vim.cmd[[hi FoldColumn guibg=blue guifg=white ctermbg=red ctermfg=black]]  -- code folds
        vim.cmd[[hi Folded ctermfg=darkgray]]
        vim.cmd[[hi clear CursorLine]]
        vim.cmd[[hi CursorLine guifg=none guibg=black ]]
        vim.cmd[[hi Search guifg=red guibg=none ]]
        vim.cmd[[hi TSConstant  guifg=lightmagenta ]]

        -- for windows
        vim.cmd [[autocmd! ColorScheme * highlight NormalFloat guibg=None]]
        vim.cmd [[autocmd! ColorScheme * highlight FloatBorder guifg=purple guibg=None]]


        vim.cmd[[hi Blamer guifg=lightgray]]
})

-- use({
--   'jessarcher/onedark.nvim',
--   config = function()
--     vim.cmd('colorscheme onedark')

--     -- Hide the characters in FloatBorder
--     vim.api.nvim_set_hl(0, 'FloatBorder', {
--       fg = vim.api.nvim_get_hl_by_name('NormalFloat', true).background,
--       bg = vim.api.nvim_get_hl_by_name('NormalFloat', true).background,
--     })

--     -- Make the StatusLineNonText background the same as StatusLine
--     vim.api.nvim_set_hl(0, 'StatusLineNonText', {
--       fg = vim.api.nvim_get_hl_by_name('NonText', true).foreground,
--       bg = vim.api.nvim_get_hl_by_name('StatusLine', true).background,
--     })

--     -- Hide the characters in CursorLineBg
--     vim.api.nvim_set_hl(0, 'CursorLineBg', {
--       fg = vim.api.nvim_get_hl_by_name('CursorLine', true).background,
--       bg = vim.api.nvim_get_hl_by_name('CursorLine', true).background,
--     })

--     vim.api.nvim_set_hl(0, 'NvimTreeIndentMarker', { fg = '#30323E' })
--     vim.api.nvim_set_hl(0, 'IndentBlanklineChar', { fg = '#2F313C' })
--   end,
-- })

-- use({
--   'tommcdo/vim-lion',
--   config = function()
--     require('user.plugins.lion')
--   end,
-- })

-- use({
--   'whatyouhide/vim-textobj-xmlattr',
--   requires = 'kana/vim-textobj-user',
-- })

-- use({
--   'sickill/vim-pasta',
--   config = function()
--     require('user.plugins.pasta')
--   end,
-- })

-- use({
--   'famiu/bufdelete.nvim',
--   config = function()
--     vim.keymap.set('n', '<Leader>q', ':Bdelete<CR>')
--   end,
-- })

-- use({
--   'lukas-reineke/indent-blankline.nvim',
--   config = function()
--     require('user.plugins.indent-blankline')
--   end,
-- })

-- use({
--   'AndrewRadev/splitjoin.vim',
--   config = function()
--     require('user.plugins.splitjoin')
--   end,
-- })

use({
  'windwp/nvim-autopairs',
  config = function()
    require('nvim-autopairs').setup()
  end,
})

-- use({
--   'akinsho/bufferline.nvim',
--   requires = 'kyazdani42/nvim-web-devicons',
--   after = 'onedark.nvim',
--   config = function()
--     require('user.plugins.bufferline')
--   end,
-- })

-- use({
--   'nvim-lualine/lualine.nvim',
--   requires = 'kyazdani42/nvim-web-devicons',
--   config = function()
--     require('user.plugins.lualine')
--   end,
-- })
use({
    'vim-airline/vim-airline',
    requires = 'vim-airline/vim-airline-themes'
})

use({
  'kyazdani42/nvim-tree.lua',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('user.plugins.nvim-tree')
  end,
})

-- use({
--   'karb94/neoscroll.nvim',
--   config = function()
--     require('user.plugins.neoscroll')
--   end,
-- })

use({
  'vim-test/vim-test',
  requires = 'nvim-neotest/neotest',
  config = function()
    require('user.plugins.vim-test')
  end,
})

use({'mgedmin/coverage-highlight.vim'})

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
  run = function() require('nvim-treesitter.install').update({ with_sync = true }) end,
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
  -- config = function()
  --   require('gitsigns').setup({
  --     sign_priority = 20,
  --     on_attach = function(bufnr)
  --       vim.keymap.set('n', ']h', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true, buffer = bufnr })
  --       vim.keymap.set('n', '[h', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true, buffer = bufnr })
  --     end,
  --   })
  -- end,
})

use({
  'neovim/nvim-lspconfig',
  requires = {
  --   'b0o/schemastore.nvim',
  --
    'nvim-lua/lsp_extensions.nvim',
    'folke/lsp-colors.nvim',
  },
  config = function()
    require('pypeaday.plugins.lspconfig')
  end,
})

use({'glepnir/lspsaga.nvim'})

use({'itchyny/vim-gitbranch'})

-- use({
--   'weilbith/nvim-code-action-menu',
--   cmd = 'CodeActionMenu',
-- })

-- use({
--   'jose-elias-alvarez/null-ls.nvim',
--   config = function()
--     require('user.plugins.null-ls')
--   end,
-- })

-- use {
--   'j-hui/fidget.nvim',
--   config = function()
--     require('fidget').setup{
--       align = {
--         bottom = false
--       }
--     }
--   end,
-- }

use({
  'L3MON4D3/LuaSnip',
  config = function()
    require('user.plugins.luasnip')
  end,
})

use({
  'hrsh7th/nvim-cmp',
  requires = {
    -- 'SirVer/ultisnips',
    -- 'quangnguyen30192/cmp-nvim-ultisnips',
    -- 'honza/vim-snippets',
    'L3MON4D3/LuaSnip',
    'hrsh7th/cmp-buffer',
    'hrsh7th/cmp-cmdline',
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-nvim-lsp-signature-help',
    'hrsh7th/cmp-nvim-lua',
    'onsails/lspkind-nvim',
    'f3fora/cmp-spell',
    -- 'saadparwaiz1/cmp_luasnip',
  },
  config = function()
    require('pypeaday.plugins.cmp')
  end,
})

-- use({
--   'phpactor/phpactor',
--   branch = 'master',
--   ft = 'php',
--   run = 'composer install --no-dev -o',
--   config = function()
--     require('user.plugins.phpactor')
--   end,
-- })

-- LaTex
use ({'lervag/vimtex'})

-- Python Specific
-- Plug 'heavenshell/vim-pydocstring', { 'do': 'make install', 'for': 'python' }
use ({
    'heavenshell/vim-pydocstring',
    run = 'make install',
    ft = {'python'},
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

-- use({
--   'luukvbaal/stabilize.nvim',
--   config = function()
--     require('stabilize').setup()
--   end,
-- })

-- use({
--   'glepnir/dashboard-nvim',
--   config = function()
--     require('user.plugins.dashboard')
--   end,
-- })

-- use({
--   'danymat/neogen',
--   config = function()
--     require('neogen').setup({})
--   end,
--   requires = 'nvim-treesitter/nvim-treesitter',
-- })

use({
  'sheerun/vim-polyglot',
})

-- Rename in a popup window
-- use({
--   'hood/popui.nvim',
--   requires = 'RishabhRD/popfix',
--   config = function()
--     vim.ui.select = require('popui.ui-overrider')
--     vim.ui.input = require('popui.input-overrider')
--   end,
-- })

use({
  'folke/trouble.nvim',
  requires = 'kyazdani42/nvim-web-devicons',
  config = function()
    require('trouble').setup()
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
