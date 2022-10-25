" set nocompatible              " be iMproved, required
" filetype off                  " required
" set background=dark
" " set the runtime path to include Vundle and initialize
" set rtp+=~/.vim/bundle/Vundle.vim
" call vundle#begin()
" 
" " let Vundle manage Vundle, required
" Plugin 'VundleVim/Vundle.vim'
" 
" " The following are examples of different formats supported.
" Plugin 'tpope/vim-fugitive'
" " Pass the path to set the runtimepath properly.
" Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" " surround
" Plugin 'tpope/vim-surround'
" " lightline
" Plugin 'itchyny/lightline.vim'
" 
" " add all your plugins here (note older versions of Vundle
" " used Bundle instead of Plugin)
" " LSP
" Plugin 'dense-analysis/ale'
" "Plugin 'davidhalter/jedi-vim'
" 
" " docstrings
" Plugin 'heavenshell/vim-pydocstring', { 'do': 'make install', 'for': 'python' }
" "
" " code folding
" Plugin 'tmhedberg/SimpylFold'
" Plugin 'vim-scripts/indentpython.vim'
" 
" " YouCompleteMe
" "Plugin 'Valloric/YouCompleteMe'
" 
" " Git
" Plugin 'zivyangll/git-blame.vim'
" 
" " syntax checking
" "Plugin 'vim-syntastic/syntastic'
" 
" " braces
" Plugin 'jiangmiao/auto-pairs'
" 
" " flake8
" "Plugin 'nvie/vim-flake8'
" 
" " syntax highlighting
" Plugin 'sheerun/vim-polyglot'
" 
" " colors
" Plugin 'jnurmine/Zenburn'
" Plugin 'altercation/vim-colors-solarized'
" Plugin 'kyoz/purify', { 'rtp': 'vim' }
" Plugin 'drewtempelmeyer/palenight.vim'
" Plugin 'ajmwagar/vim-deus'
" Plugin 'cocopon/pgmnt.vim'
" Plugin 'cocopon/iceberg.vim'
" Plugin 'chriskempson/base16-vim'
" Plugin 'ghifarit53/tokyonight-vim'
" 
" " file browsing
" Plugin 'junegunn/fzf'
" Plugin 'junegunn/fzf.vim'
" Plugin 'mileszs/ack.vim'
" 
" " Indent guide
" Plugin 'nathanaelkane/vim-indent-guides'
" " All of your Plugins must be added before the following line
" call vundle#end()            " required
" filetype plugin indent on    " required
" " To ignore plugin indent changes, instead use:
" "filetype plugin on
" "
" " Brief help
" " :PluginList       - lists configured plugins
" " :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" " :PluginSearch foo - searches for foo; append `!` to refresh local cache
" " :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
" "
" " see :h vundle for more details or wiki for FAQ
" " Put your non-Plugin stuff after this line
" " handy shortcuts
" let mapleader=" "
" nnoremap <leader><cr> :source ~/.vimrc<cr>
" nnoremap <leader>1 :ALEFix<cr><cr>
" nnoremap <leader>g :GFiles<cr>
" nnoremap <leader>d :ALEGoToDefinition<cr>
" nnoremap <leader>r :Ag<cr>
" nnoremap <Leader>s :<C-u>call gitblame#echo()<CR>
" 
" " remap visual block mode so ctrl v can be paste
" command! Vb normal! <C-v>
" nnoremap <leader>b :Vb<CR>
" " copy to clipboard
" " copy with ctrl c
" vnoremap <C-c> :w !pbcopy<CR><CR>
" " paste with ctrl v
" nnoremap <C-v> :r !pbpaste<CR><CR>
" " search
" let g:ackprg = 'ag --vimgrep'
" 
" " Add fzf to vim
" set rtp+=/usr/local/opt/fzf
" 
" filetype plugin indent on    " required
" 
" "split navigations
" nnoremap <C-J> <C-W><C-J>
" nnoremap <C-K> <C-W><C-K>
" nnoremap <C-L> <C-W><C-L>
" nnoremap <C-H> <C-W><C-H>
" 
" " flake8
" let g:flake8_cmd='/usr/local/bin/flake8'
" let g:flake8_quickfix_location="topleft"
" " YVM
" 
" " let g:ycm_python_interpreter_path = ''
" " let g:ycm_python_sys_path = []
" " let g:ycm_extra_conf_vim_data = [
" "   \  'g:ycm_python_interpreter_path',
" "   \  'g:ycm_python_sys_path'
" "   \]
" " let g:ycm_global_ycm_extra_conf = '~/yvm_global_extra_conf.py'
" 
" " linting with Ale
" let b:ale_linters = {'python': ['gitlint','flake8', 'mypy', 'autoflake', "pyright"]} "'vulture','pyright', 'pyls',
" let g:ale_python_mypy_options = '--show-error-codes'
" "let b:ale_fixers =  ['black', 'isort', 'remove_trailing_lines', 'reorder-python-imports', 'trim_whitespace']
" let b:ale_fixers = {'python': ['black', 'isort', 'remove_trailing_lines', 'reorder-python-imports', 'trim_whitespace']}
" let b:ale_fix_on_save = 0
" let g:ale_echo_msg_error_str = 'E'
" let g:ale_echo_msg_warning_str = 'W'
" let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
" let g:ale_set_baloons = 1
" let g:ale_completion_enabled = 1
" " Enable backspace
" :set backspace=indent,eol,start
" 
" " Enable folding
" set foldmethod=indent
" set foldlevel=99
" 
" " Enable folding with the spacebar
" nnoremap <space> za
" 
" " enable syntax highlighting
" let g:python_syntax_highlighting = 0
" 
" syntax enable
" set statusline+=%#warningmsg#
" "set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*
" 
" "let g:syntastic_always_populate_loc_list = 1
" "let g:syntastic_auto_loc_list = 1
" "let g:syntastic_check_on_open = 1
" "let g:syntastic_check_on_wq = 0
" "let g:syntastic_python_checkers = ['flake8']
" 
" " doq for pydocstring
" let g:pydocstring_doq_path = '/usr/local/bin/doq'
" 
" " General VIM
" " show line numbers
" set number relativenumber
" 
" " set tabs to have 4 spaces
" set ts=4
" 
" " indent when moving to the next line while writing code
" set autoindent
" 
" " expand tabs into spaces
" set expandtab
" 
" " when using the >> or << commands, shift lines by 4 spaces
" set shiftwidth=4
" 
" " show a visual line under the cursor's current line
" set cursorline
" 
" " show the matching part of the pair for [] {} and ()
" set showmatch
" 
" " set python style line folding
" let g:vim_markdown_folding_style_pythonic = 1
" 
" " syntax
" let g:markdown_fenced_languaged = ['python', 'bash=sh']
" 
" " show docstring for folded code
" let g:SimpylFold_docstring_preview=1
" 
" call togglebg#map("<F5>")
" 
" " indent guide
" let g:indent_guides_enable_on_vim_startup = 1
" 
" " theme
" "let g:tokyonight_style = 'storm'
" "let g:tokyonight_enable_italic = 1
" 
" colorscheme iceberg
" " indents
" "hi IndentGuidesOdd  ctermbg=black
" "hi IndentGuidesEven ctermbg=darkgrey
" 
" "lightline
" "let g:lightline = {'colorscheme': 'tokyonight'}
" let g:lightline = {'colorscheme': 'iceberg'}
" set laststatus=2
