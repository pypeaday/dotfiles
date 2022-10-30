vim.cmd([[
    let g:python_lint_config = '~/pylint.rc'
    let g:python3_host_prog = '~/dotfiles/.venv/nvim/bin/python'
    " flake8
    let g:flake8_cmd='flake8'
    let g:flake8_show_quickfix=1 
    let g:flake8_quickfix_location="top-left"
    let g:flake8_quickfix_height=3
    let g:flake8_error_marker='EE'     
    let g:flake8_warning_marker='WW'  
    let g:flake8_pyflake_marker=''   
    let g:flake8_complexity_marker=''
    let g:flake8_naming_marker=''   

    let g:pydocstring_formatter='google'
    let g:pydocstring_doq_path = '$HOME/.local/bin/doq'

    let g:vim_markdown_folding_style_pythonic = 1
    let g:markdown_fenced_languages = ['python', 'bash=sh', 'json', 'yaml']
    let g:SimpylFold_docstring_preview=1

    let g:indent_guides_enable_on_vim_startup = 1

    "search
    let g:ackprg = 'ag --vimgrep --hidden'

    "-- If you want to use snippet for multiple filetypes, you can `g:vsnip_filetypes` for it.
    let g:vsnip_filetypes = {}

    "Try ultisnip
    "-- Trigger configuration. You need to change this to something other than <tab> if you use one of the following:
    let g:UltiSnipsExpandTrigger="<tab>"
    let g:UltiSnipsJumpForwardTrigger="<C-e>"
    let g:UltiSnipsJumpBackwardTrigger="<C-i>"

    "-- If you want :UltiSnipsEdit to split your window.
    let g:UltiSnipsEditSplit="vertical"


    "-- nerdtree
    "-- let NERDTreeShowHidden=1
    "-- let g:NERDTreeExtensionHighlightColor = {} " this line is needed to avoid error
    "-- let g:NERDTreeExtensionHighlightColor['py'] = "689FB6"
    "
    "-- LaTex
    "-- This is necessary for VimTeX to load properly. The "indent" is optional.
    "-- Note that most plugin managers will do this automatically.
    filetype plugin indent on

    "-- Viewer options: One may configure the viewer either by specifying a built-in
    "-- viewer method:
    "-- let g:vimtex_view_method = 'okular'
    "
    "-- Or with a generic interface:
    let g:vimtex_view_general_viewer = 'okular'
    let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'
    let g:vimtex_view_general_options_latexmk = '--unique'

    "-- VimTeX uses latexmk as the default compiler backend. If you use it, which is
    "-- strongly recommended, you probably don't need to configure anything. If you
    "-- want another compiler backend, you can change it as follows. The list of
    "-- supported backends and further explanation is provided in the documentation,
    "-- see ":help vimtex-compiler".
    let g:vimtex_compiler_method = 'latexrun'
    let g:vimtex_compiler_method = 'latexmk'

    "-- Most VimTeX mappings rely on localleader and this can be changed with the
    "-- following line. The default is usually fine and is the symbol "\".
    let maplocalleader = ","

    "-- not for me
    let g:loaded_ruby_provider = 0
    let g:loaded_perl_provider = 0

]])
