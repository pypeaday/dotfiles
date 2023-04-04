return {

  "glepnir/lspsaga.nvim",
  event = "LspAttach",
  config = function()
    local keymap = vim.keymap.set
    local saga = require("lspsaga")

    saga.setup({})

    -- Lsp finder find the symbol definition implement reference
    -- if there is no implement it will hide
    -- when you use action in finder like open vsplit then you can
    -- use <C-t> to jump back
    keymap("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", { silent = true })

    -- Rename
    keymap("n", "<leader>gr", "<cmd>Lspsaga rename<CR>", { silent = true })

    -- Peek Definition
    -- you can edit the definition file in this flaotwindow
    -- also support open/vsplit/etc operation check definition_action_keys
    -- support tagstack C-t jump back
    keymap("n", "<leader>pd", "<cmd>Lspsaga peek_definition<CR>", { silent = true })

    -- Show line diagnostics
    keymap("n", "<leader>cd", "<cmd>Lspsaga show_line_diagnostics<CR>", { silent = true })

    -- Show cursor diagnostic
    keymap("n", "<leader>cd", "<cmd>Lspsaga show_cursor_diagnostics<CR>", { silent = true })

    -- Diagnsotic jump can use `<c-o>` to jump back
    keymap("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { silent = true })
    keymap("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", { silent = true })

    -- Outline
    keymap("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { silent = true })
  end,
  dependencies = {
    { "nvim-tree/nvim-web-devicons" },
    --Please make sure you install markdown and markdown_inline parser
    { "nvim-treesitter/nvim-treesitter" },
  },
}
