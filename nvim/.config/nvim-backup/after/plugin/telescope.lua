local nnoremap = require('pypeaday.keymap_function').nnoremap
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local actions = require("telescope.actions")


require("telescope").setup({
    defaults = {
        layout_strategy = 'vertical',
        layout_config = { height = 0.8 },
        prompt_prefix = " >",
        color_devicons = true,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        -- find_command = {
        --     'rg',
        --     '--no-ignore',
        --     '--files',
        --     '--hidden',
        --     -- '--ignore-file',
        --     -- '.venv',
        --     '-g',
        --     '!.git'
        -- },
        vimgrep_arguments = {
            'rg',
            '--no-ignore',
            '--hidden',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '-u'
        },
        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        file_ignore_patterns = { 'markout/', '.markata.cache/', 'logs/', 'build/', '.venv/', '.git/', '.pyc',
            'mypy_cache', 'htmlcov', 'pytest_cache' },
        mappings = {
            i = {
                ["<C-x>"] = false,
                ["<C-q>"] = actions.send_to_qflist,
            },
        },
    },
    pickers = {
        find_files = {
            hidden = true,
            -- theme = "dropdown"
        }
    },
    extensions = {
    },
})

----require("telescope").load_extension("git_worktree")
---- require("telescope").load_extension("fzy_native")
require("telescope").load_extension("fzf")
--require("telescope").load_extension("live_grep_args")
nnoremap("gen", "<cmd>Telescope find_files cwd=~/.config/nvim <CR>")
nnoremap("<leader>ps", "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<CR>")
nnoremap("<Leader>pf",
    "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--iglob', '!.venv','-g' ,'!.git' }})<cr>")
nnoremap("<Leader>pg", "<cmd>lua require('telescope.builtin').live_grep()<CR>")
nnoremap("<leader>pw", "<cmd>lua require('telescope.builtin').grep_string { search =  vim.fn.expand(\"<cword>\") }<CR>")
nnoremap("<leader>pb", "<cmd>lua require('telescope.builtin').buffers()<CR>")
nnoremap("<leader>pl", "<cmd>lua require('telescope.builtin').loclist()<CR>")
nnoremap("<leader>ch", "<cmd>lua require('telescope.builtin').help_tags()<CR>")
