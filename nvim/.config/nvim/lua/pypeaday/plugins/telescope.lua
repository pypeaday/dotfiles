local nnoremap = require('pypeaday.keymap_function').nnoremap
--local pickers = require("telescope.pickers")
--local finders = require("telescope.finders")
--local previewers = require("telescope.previewers")
--local action_state = require("telescope.actions.state")
--local conf = require("telescope.config").values
--local actions = require("telescope.actions")

-- You dont need to set any of these options. These are the default ones. Only
-- the loading is important
require('telescope').setup {
  extensions = {
    fzf = {
      fuzzy = true,                    -- false will only do exact matching
      override_generic_sorter = true,  -- override the generic sorter
      override_file_sorter = true,     -- override the file sorter
      case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
                                       -- the default case_mode is "smart_case"
    }
  }
}
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require('telescope').load_extension('fzf')

----local actions = require("telescope.actions")
----require("telescope").setup({
----    defaults = {
----        layout_strategy = 'vertical',
----        layout_config = { height = 0.8 },
----        prompt_prefix = " >",
----        color_devicons = true,
----        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
----        find_command = {
----            'rg', 
----            '--no-ignore',
----            '--files',
----            '--hidden',  
----            -- '--ignore-file',
----            -- '.venv',
----            '-g',
----            '!.git' 
----        },
----        vimgrep_arguments = {
----              'rg',
----              '--no-ignore',
----              '--hidden',
----              '--with-filename',
----              '--line-number',
----              '--column',
----              '--smart-case',
----              '-u'},
----        grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
----        qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
----        file_ignore_patterns = {'markout/', '.markata.cache/', 'logs/','build/','.venv/','.venv3/','.git/', '.pyc', 'mypy_cache', 'htmlcov', 'pytest_cache'},
----        mappings = {
----            i = {
----                ["<C-x>"] = false,
----                ["<C-q>"] = actions.send_to_qflist,
----            },
----        },
----    },
----    pickers = {
----        find_files = {
----            hidden = true,
----            -- theme = "dropdown"
----        }
----    },
----    extensions = {
----    },
----})

----require("telescope").load_extension("git_worktree")
---- require("telescope").load_extension("fzy_native")
--require("telescope").load_extension("fzf")
--require("telescope").load_extension("live_grep_args")

nnoremap("gen", "<cmd>Telescope find_files cwd=~/.config/nvim<CR>")
nnoremap("<leader>ps", "<cmd>lua require('telescope.builtin').grep_string({ search = vim.fn.input('Grep For > ')})<CR>")  
nnoremap("<Leader>pf", "<cmd>lua require'telescope.builtin'.find_files({ find_command = {'rg', '--files','--no-ignore', '--hidden',  '--ignore-file', '.venv','-g' ,'!.git' }})<cr>")  
nnoremap("<Leader>pg", "<cmd>lua require('telescope.builtin').live_grep()<CR>")  
nnoremap("<leader>pw", "<cmd>lua require('telescope.builtin').grep_string { search =  vim.fn.expand(\"<cword>\") }<CR>")  
nnoremap("<leader>pb", "<cmd>lua require('telescope.builtin').buffers()<CR>")  
nnoremap("<leader>ch", "<cmd>lua require('telescope.builtin').help_tags()<CR>")  
nnoremap("<leader>pl", "<cmd>lua require('telescope.builtin').loclist()<CR>") 
