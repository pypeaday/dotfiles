-- switching to nvim-tree to align with JA -> will try to get NERDTree stuff working the same
-- " nerdtree
-- let NERDTreeShowHidden=1
-- let g:NERDTreeExtensionHighlightColor = {} " this line is needed to avoid error
-- let g:NERDTreeExtensionHighlightColor['py'] = "689FB6"
-- vim.g.nvim_tree_indent_markers = 1
-- vim.g.nvim_tree_git_hl = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require('nvim-tree').setup({
  git = {
    ignore = false,
  },
  renderer = {
    highlight_opened_files = '1',
    group_empty = true,
    icons = {
      show = {
        folder_arrow = true,
      },
    },
    indent_markers = {
      enable = true,
      -- inline_arrows = false,
    },
  },
})

vim.cmd([[
  highlight NvimTreeIndentMarker guifg=#30323E
  augroup NvimTreeHighlights
    autocmd ColorScheme * highlight NvimTreeIndentMarker guifg=#30323E
  augroup end
]])

vim.keymap.set('n', '<leader>tt', ':NvimTreeToggle<CR>')
