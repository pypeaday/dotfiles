-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
-- null-ls setup for formatting
local null_ls = require("null-ls")

local h = require("null-ls.helpers")
local methods = require("null-ls.methods")

local FORMATTING = methods.internal.FORMATTING

null_ls.builtins.formatting.tidy_import = h.make_builtin({
  name = "tidy_import",
  meta = {
    url = "https://github.com/deshaw/pyflyby",
    description = "automatic imports for python",
  },
  method = FORMATTING,
  filetypes = { "python" },
  generator_opts = {
    command = "tidy-imports",
    args = {
      "--quiet",
      "--replace-star-imports",
      "--add-missing",
      "--replace",
      "--separate-from-imports",
      "--remove-unused",
      "$FILENAME",
    },
    to_stdin = false,
    to_temp_file = true,
  },
  factory = h.formatter_factory,
})

null_ls.builtins.formatting.ruff = h.make_builtin({
  name = "ruff",
  meta = {
    url = "https://github.com/charliermarsh/ruff",
    description = "Ruff - super fast formatting and linting for Python with Rust",
  },
  method = FORMATTING,
  filetypes = { "python" },
  generator_opts = {
    command = "ruff check",
    args = {
      "$FILENAME",
      "--fix",
    },
    to_stdin = false,
    to_temp_file = true,
  },
  factory = h.formatter_factory,
})

local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
null_ls.setup({
  sources = {
    -- formatting
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.yamlfmt,
    null_ls.builtins.formatting.sqlformat,
    null_ls.builtins.formatting.beautysh,
    null_ls.builtins.formatting.trim_whitespace,
    null_ls.builtins.formatting.trim_newlines,
    null_ls.builtins.formatting.json_tool,
    null_ls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
    -- null_ls.builtins.formatting.tidy_import,
    null_ls.builtins.formatting.ruff,
    null_ls.builtins.formatting.isort.with({ extra_args = { "--sl" } }),

    -- diagnostics
    null_ls.builtins.diagnostics.markdownlint,
    null_ls.builtins.diagnostics.hadolint,

    -- completions
    null_ls.builtins.completion.spell,

    null_ls.builtins.code_actions.gitsigns,
  },
  on_attach = function(client, bufnr)
    if client.supports_method("textDocument/formatting") then
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
      vim.api.nvim_create_autocmd("BufWritePre", {
        -- group = M.waylonwalker_augroup,
        group = augroup,
        buffer = bufnr,
        callback = function()
          -- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
          vim.lsp.buf.format()
        end,
      })
    end
  end,
})
