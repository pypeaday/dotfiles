vim.cmd([[
    " TODO: make this a flake8 config?
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

    "-- not for me
    let g:loaded_ruby_provider = 0
    let g:loaded_perl_provider = 0

]])
