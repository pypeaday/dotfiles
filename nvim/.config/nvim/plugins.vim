       " _             _                 _           
 " _ __ | |_   _  __ _(_)_ __  _____   _(_)_ __ ___  
" | '_ \| | | | |/ _` | | '_ \/ __\ \ / / | '_ ` _ \ 
" | |_) | | |_| | (_| | | | | \__ \\ V /| | | | | | |
" | .__/|_|\__,_|\__, |_|_| |_|___(_)_/ |_|_| |_| |_|
" |_|            |___/                               
"
"―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 
call plug#begin('~/.local/share/nvim/plugged')

Plug 'jim-at-jibba/ariake-vim-colors'

Plug 'godlygeek/tabular'

Plug 'onsails/lspkind-nvim'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/nvim-cmp'
Plug 'f3fora/cmp-spell'

Plug 'waylonwalker/Telegraph.nvim'

" LaTex
Plug 'lervag/vimtex'

" For ultisnips users.
Plug 'SirVer/ultisnips'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'
Plug 'honza/vim-snippets'

Plug 'sheerun/vim-polyglot'
Plug 'jbyuki/instant.nvim'
Plug 'folke/trouble.nvim'
Plug 'folke/which-key.nvim'
Plug 'Pocco81/TrueZen.nvim'
"Plug 'windwp/nvim-spectre'
Plug 'heavenshell/vim-pydocstring', { 'do': 'make install', 'for': 'python' }
Plug 'ThePrimeagen/vim-be-good'

" Git
Plug 'zivyangll/git-blame.vim'
Plug 'tpope/vim-fugitive'
Plug 'itchyny/vim-gitbranch'
Plug 'mhinz/vim-signify'
Plug 'AndrewRadev/diffurcate.vim'

" syntax checking
Plug 'vim-syntastic/syntastic'
Plug 'nvie/vim-flake8'

" braces
Plug 'jiangmiao/auto-pairs'

" Statusline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" color
Plug 'folke/tokyonight.nvim'
" Plug 'fladson/vim-kitty'

" splash screen
" using https link since git username error
" Plug 'mhinz/vim-stratify'
Plug 'https://github.com/mhinz/vim-startify'

" navigation
Plug 'ThePrimeagen/harpoon'
Plug 'christoomey/vim-quicklink'
Plug 'christoomey/vim-tmux-runner'
Plug 'fabi1cazenave/termopen.vim'
Plug 'junegunn/fzf', { 'do': 'yes \| ./install'  }
Plug 'junegunn/fzf.vim'
Plug 'cloudhead/neovim-fuzzy'
Plug 'justinmk/vim-sneak'
Plug 'mbbill/undotree'
Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-fzy-native.nvim'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'smitajit/bufutils.vim'
Plug 'voldikss/vim-floaterm'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-dispatch'
Plug 'tpope/vim-repeat'

" File Tree
" Plug 'kyazdani42/nvim-tree.lua'
Plug 'preservim/nerdtree'

" objects
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} 
Plug 'nvim-treesitter/nvim-treesitter-textobjects'
Plug 'nvim-treesitter/playground'
Plug 'thinca/vim-visualstar'
Plug 'wellle/targets.vim'
Plug 'tpope/vim-commentary'

" lsp
Plug 'folke/lsp-colors.nvim'
"Plug 'tami5/lspsaga.nvim'
Plug 'glepnir/lspsaga.nvim'
Plug 'hrsh7th/nvim-compe'
Plug 'tzachar/compe-tabnine', { 'do': './install.sh' }
Plug 'kabouzeid/nvim-lspinstall'
Plug 'michaeljsmith/vim-indent-object'
Plug 'neovim/nvim-lspconfig'
Plug 'nvim-lua/lsp_extensions.nvim'
Plug 'nvim-lua/plenary.nvim'

" testing
Plug 'vim-test/vim-test'
" Plug 'rcarriga/vim-ultest'
Plug 'antoinemadec/FixCursorHold.nvim'
Plug 'nvim-neotest/neotest'
"Plug 'mfussenegger/nvim-dap'
"Plug 'nvim-telescope/telescope-dap.nvim'
"Plupg 'mfussenegger/nvim-dap-python'

" Coverage
Plug 'mgedmin/coverage-highlight.vim'

" Plug 'hrsh7th/vim-vsnip/'
" Plug 'L3MON4D3/LuaSnip'

" prettier
Plug 'sbdchd/neoformat'

" emoji
" Plug 'junegunn/vim-emoji'

" icons need loaded last
Plug 'tiagofumo/vim-nerdtree-syntax-highlight'
Plug 'ryanoasis/vim-devicons'
Plug 'PhilRunninger/nerdtree-visual-selection'
Plug 'kyazdani42/nvim-web-devicons' " for file icons


Plug 'laytan/cloak.nvim'

Plug 'APZelos/blamer.nvim'
Plug 'lfv89/vim-interestingwords'

Plug 'amrbashir/nvim-docs-view', { 'on': 'DocsViewToggle'}


call plug#end()

