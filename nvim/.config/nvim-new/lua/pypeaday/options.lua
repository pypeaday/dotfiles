-- like my settings file
--
--"           _   _   _                       _           
--"  ___  ___| |_| |_(_)_ __   __ _ _____   _(_)_ __ ___  
--" / __|/ _ \ __| __| | '_ \ / _` / __\ \ / / | '_ ` _ \ 
--" \__ \  __/ |_| |_| | | | | (_| \__ \\ V /| | | | | | |
--" |___/\___|\__|\__|_|_| |_|\__, |___(_)_/ |_|_| |_| |_|
--"                           |___/                       
--"―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― 

set rtp+=~/.local/share/nvim/plugged/fzf/bin/fzf

-- General VIM
-- show line numbers
set number relativenumber

-- set tabs to have 4 spaces
set ts=4

-- indent when moving to the next line while writing code
set autoindent

-- expand tabs into spaces
set expandtab

-- when using the >> or << commands, shift lines by 4 spaces
set shiftwidth=4

-- show a visual line under the cursor's current line
set cursorline

-- show the matching part of the pair for [] {} and ()
set showmatch

-- cmp
set completeopt=menu,menuone,noselect

-- Enable folding
set foldmethod=indent
set foldlevel=99

syntax enable
set statusline+=%#warningmsg#
set statusline+=%*
set laststatus=2
set scrolloff=30
set nowrap
set colorcolumn=88
set list
set listchars=tab:▸\ ,trail:·

-- Ignore files
set wildignore+=*.pyc
set wildignore+=*_build/*
set wildignore+=**/coverage/*
set wildignore+=**/.git/*
set wildignore+=**/.venv/*

set clipboard+=unnamedplus

set runtimepath+=~/.config/nvim/my-snippets/UltiSnips/
let g:python_lint_config = '~/pylint.rc'
let g:python3_host_prog = '~/dotfiles/.venv/nvim/bin/python'

--LSP
--flake8
let g:flake8_cmd='flake8'
 --  show (default)
let g:flake8_show_quickfix=1 
let g:flake8_quickfix_location="top-left"
let g:flake8_quickfix_height=3
let g:flake8_error_marker='EE'     
let g:flake8_warning_marker='WW'  
let g:flake8_pyflake_marker=''   
let g:flake8_complexity_marker=''
let g:flake8_naming_marker=''   



--search
let g:ackprg = 'ag --vimgrep --hidden'

--Snippets vim vim-vsnip

-- If you want to use snippet for multiple filetypes, you can `g:vsnip_filetypes` for it.
let g:vsnip_filetypes = {}

-- Try ultisnip
-- Trigger configuration. You need to change this to something other than <tab> if you use one of the following:
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<C-e>"
let g:UltiSnipsJumpBackwardTrigger="<C-i>"

-- If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

-- Add fzf to vim

let g:airline_theme="night_owl"
let g:airline_powerline_fonts = 1

-- doq for pydocstring
let g:pydocstring_formatter='google'
let g:pydocstring_doq_path = '$HOME/.local/bin/doq'

-- set python style line folding
let g:vim_markdown_folding_style_pythonic = 1

-- syntax
let g:markdown_fenced_languages = ['python', 'bash=sh', 'json', 'yaml']

-- show docstring for folded code
let g:SimpylFold_docstring_preview=1

-- indent guide
let g:indent_guides_enable_on_vim_startup = 1


-- nerdtree
-- let NERDTreeShowHidden=1
-- let g:NERDTreeExtensionHighlightColor = {} " this line is needed to avoid error
-- let g:NERDTreeExtensionHighlightColor['py'] = "689FB6"

-- LaTex
-- This is necessary for VimTeX to load properly. The "indent" is optional.
-- Note that most plugin managers will do this automatically.
filetype plugin indent on

-- Viewer options: One may configure the viewer either by specifying a built-in
-- viewer method:
-- let g:vimtex_view_method = 'okular'

-- Or with a generic interface:
let g:vimtex_view_general_viewer = 'okular'
let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'
let g:vimtex_view_general_options_latexmk = '--unique'

-- VimTeX uses latexmk as the default compiler backend. If you use it, which is
-- strongly recommended, you probably don't need to configure anything. If you
-- want another compiler backend, you can change it as follows. The list of
-- supported backends and further explanation is provided in the documentation,
-- see ":help vimtex-compiler".
let g:vimtex_compiler_method = 'latexrun'
let g:vimtex_compiler_method = 'latexmk'

-- Most VimTeX mappings rely on localleader and this can be changed with the
-- following line. The default is usually fine and is the symbol "\".
let maplocalleader = ","

-- testing
let test#python#runner = 'pytest'
let test#python#pytest#options = "--color=yes"
let g:ultest_use_pty = 1


-- not for me
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0

-- git blame (git lens)
let g:blamer_enabled = 1
let g:blamer_prefix = ' > '
let g:blamer_show_in_visual_modes = 0
let g:blamer_show_in_insert_modes = 0
let g:blamer_delay = 500
-- Available options: <author>, <author-mail>, <author-time>, <committer>, <committer-mail>, <committer-time>, <summary>, <commit-short>, <commit-long>
let g:blamer_template = '<committer>, <committer-time>, <summary>'
let g:blamer_relative_time = 0 
