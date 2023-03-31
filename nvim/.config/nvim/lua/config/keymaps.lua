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
  { nnoremap = true, desc = "Go to prev" }
)
vim.keymap.set(
  "n",
  "<silent> )) ",
  "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>",
  { nnoremap = true, desc = "Go to next" }
)
vim.keymap.set("n", "<leader>vd", "<cmd>lua vim.lsp.buf.definition()<CR>", { nnoremap = true, desc = "" })
vim.keymap.set("n", "<leader>vD", "<cmd>lua vim.lsp.buf.declaration()<CR>", { nnoremap = true, desc = "" })
vim.keymap.set("n", "<leader>vh", "<cmd>lua vim.lsp.buf.hover()<CR>", { nnoremap = true, desc = "" })
vim.keymap.set("n", "<leader>vi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { nnoremap = true, desc = "" })
vim.keymap.set("n", "<leader>vsh", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { nnoremap = true, desc = "" })
-- nnoremap("<leader>vrr", "<cmd>lua vim.lsp.buf.references()<CR>")
vim.keymap.set("n", "<leader>vrr", ":Telescope lsp_references<CR>", { nnoremap = true, desc = "" })
vim.keymap.set("n", "<leader>vrn", "<cmd>lua vim.lsp.buf.rename()<CR>", { nnoremap = true, desc = "" })
vim.keymap.set("n", "<leader>vca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { nnoremap = true, desc = "" })
-- " show_line_diagnostics deprecated for open_float
vim.keymap.set("n", "<leader>vsd", " vim.diagnostic.open_float()<CR>  ", { nnoremap = true, desc = "" })
vim.keymap.set(
  "n",
  "<leader>vsl",
  "<cmd> lua vim.diagnostic.setloclist({open=false})<CR>",
  { nnoremap = true, desc = "" }
)
vim.keymap.set("n", "<leader>vn", "<cmd>lua vim.lsp.diagnostic.goto_next()<CR>", { nnoremap = true, desc = "" })
