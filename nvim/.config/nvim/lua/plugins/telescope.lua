return {
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local previewers = require("telescope.previewers")
        local action_state = require("telescope.actions.state")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")

        require("telescope").setup({
          defaults = {
            layout_strategy = "vertical",
            layout_config = { height = 0.8 },
            prompt_prefix = " >",
            color_devicons = true,
            file_previewer = previewers.vim_buffer_cat.new,
            -- find_command = { "rg", "--files", "--no-ignore", "--hidden", "--iglob", "!.venv", "-g", "!.git" },
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
            -- using ag was a little slower than rg for me
            -- vimgrep_arguments = { "ag", "--vimgrep", "--unrestricted", "--ignore", ".venv" },
            vimgrep_arguments = {
              "rg",
              "--no-ignore",
              "--hidden",
              "--with-filename",
              "--line-number",
              "--column",
              "--smart-case",
              "-u",
            },
            grep_previewer = previewers.vim_buffer_vimgrep.new,
            qflist_previewer = previewers.vim_buffer_qflist.new,
            file_ignore_patterns = {
              "markout/",
              ".markata.cache/",
              "logs/",
              "build/",
              ".venv/",
              ".git/",
              ".pyc",
              "mypy_cache",
              "htmlcov",
              "pytest_cache",
              ".null-ls*.py",
            },
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
              -- theme = "dropdown",
            },
          },
          extensions = {},
        })

        require("telescope").load_extension("fzf")
      end,
    },
  },
}
