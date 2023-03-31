vim.cmd([[
let g:blamer_enabled = 1
let g:blamer_prefix = ' > '
let g:blamer_show_in_visual_modes = 0
let g:blamer_show_in_insert_modes = 0
let g:blamer_delay = 500
" Available options: <author>, <author-mail>, <author-time>, <committer>, <committer-mail>, <committer-time>, <summary>, <commit-short>, <commit-long>
let g:blamer_template = '<committer>, <committer-time>, <summary>'
let g:blamer_relative_time = 0 
    ]])
