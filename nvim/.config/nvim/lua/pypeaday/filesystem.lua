local map = vim.api.nvim_set_keymap
local default_opts = {noremap = true}

-- require'nvim-tree'.setup()
-- require'nvim-web-devicons'.setup()
-- map('n', '<leader>tt', ':NvimTreeToggle<CR>', {noremap = true, silent = true})
map('n', '<leader>tt', ':NERDTreeToggle<CR>', {noremap = true, silent = true})
