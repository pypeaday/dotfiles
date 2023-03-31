-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<esc>", { desc = "Exit Insert Mode with jk" })

-- lsp
vim.keymap.set("i", "jk", "<esc>", { desc = "Exit Insert Mode with jk" })
vim.keymap.set(
  "n",
  "<silent> (( ",
  "<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>",
  { noremap = true, desc = "Go to prev" }
)
vim.keymap.set(
  "n",
  "<silent> )) ",
  "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>",
  { noremap = true, desc = "Go to next" }
)
vim.keymap.set("n", "<leader>vd", "<cmd>lua vim.lsp.buf.definition()<CR>", { noremap = true, desc = "" })
vim.keymap.set("n", "<leader>vD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { noremap = true, desc = "" })
vim.keymap.set("n", "<leader>vh", "<cmd>lua vim.lsp.buf.hover()<CR>", { noremap = true, desc = "" })
vim.keymap.set("n", "<leader>vi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { noremap = true, desc = "" })
vim.keymap.set("n", "<leader>vsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { noremap = true, desc = "" })
-- noremap("<leader>vrr", "<cmd>lua vim.lsp.buf.references()<CR>")
vim.keymap.set("n", "<leader>vrr", ":Telescope lsp_references<CR>", { noremap = true, desc = "" })
vim.keymap.set("n", "<leader>vrn", "<cmd>lua vim.lsp.buf.rename()<CR>", { noremap = true, desc = "" })
vim.keymap.set("n", "<leader>vca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { noremap = true, desc = "" })
-- " show_line_diagnostics deprecated for open_float
vim.keymap.set("n", "<leader>vsd", " vim.diagnostic.open_float()<CR>  ", { noremap = true, desc = "" })
vim.keymap.set(
  "n",
  "<leader>vsl",
  "<cmd> lua vim.diagnostic.setloclist({open=false})<CR>",
  { noremap = true, desc = "" }
)
vim.keymap.set("n", "<leader>vn", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", { noremap = true, desc = "" })
