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
    null_ls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
    -- null_ls.builtins.formatting.tidy_import,
    null_ls.builtins.formatting.ruff,
    null_ls.builtins.formatting.prettier,
    null_ls.builtins.formatting.yamlfmt,
    null_ls.builtins.formatting.sqlformat,
    null_ls.builtins.formatting.beautysh,
    null_ls.builtins.formatting.trim_whitespace,
    null_ls.builtins.formatting.trim_newlines,
    null_ls.builtins.formatting.json_tool,
    null_ls.builtins.diagnostics.hadolint,
    null_ls.builtins.formatting.isort.with({ extra_args = { "--sl" } }),

    -- diagnostics
    -- null_ls.builtins.diagnostics.eslint,
    null_ls.builtins.diagnostics.markdownlint,
    -- do I need flake8 config in pylsp setup?
    -- null_ls.builtins.diagnostics.flake8,

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

local lsp = require("lsp-zero")

lsp.preset("recommended")

lsp.ensure_installed({
  "ruff_lsp",
  "pylsp",
  "jedi_language_server",
  "dockerls",
  "bashls",
  "yamlls",
  "jsonls",
  "html",
  "terraformls",
  "marksman",
})

lsp.configure("pylsp", {
  settings = {
    pylsp = {
      configurationSources = { "flake8" },
      plugins = {
        pycodestyle = { enabled = false },
        flake8 = { enabled = true },
        mypy = {
          enabled = true,
          live_mode = true,
          strict = true,
        },
        jedi_completion = { fuzzy = true, enabled = true },
        jedi_hover = { enabled = true },
        jedi_references = { enabled = true },
        jedi_signature_help = { enabled = true },
        jedi_symbols = { enabled = true, all_scopes = true },
      },
    },
  },
})

-- Configure `ruff-lsp`.
-- See: https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#ruff_lsp
-- For the default config, along with instructions on how to customize the settings
require("lspconfig").ruff_lsp.setup({
  -- on_attach = on_attach,
  init_options = {
    settings = {
      -- Any extra CLI arguments for `ruff` go here.
      -- args = {
      --   "--config=$HOME/dotfiles/ruff/ruff.toml",
      -- },
      logLevel = "error",
    },
  },
})

local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_sources = {
  { name = "luasnip" },
  { name = "nvim_lsp" },
  { name = "nvim_lsp_signature_help" },
  { name = "nvim_lua" },
  { name = "treesitter" },
  { name = "buffer" },
  { name = "path" },
  { name = "tmux" },
  -- { name = "spell" },
  { name = "git" },
  { name = "rg" },
}
local lspkind = require("lspkind")
local cmp_formatting = {
  format = lspkind.cmp_format({
    mode = "symbol", -- show only symbol annotations
    maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
    ellipsis_char = "...", -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)
  }),
}
local cmp_mappings = lsp.defaults.cmp_mappings({
  ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
  ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
  ["<C-y>"] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
  ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
  ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
  ["<C-d>"] = cmp.mapping.scroll_docs(-4),
  ["<C-f>"] = cmp.mapping.scroll_docs(4),
  ["<C-e>"] = cmp.mapping.close(),
  ["<CR>"] = cmp.mapping.confirm({
    behavior = cmp.ConfirmBehavior.Replace,
    select = true,
  }),
})

-- disable completion with tab
-- this helps with copilot setup
cmp_mappings["<Tab>"] = nil
cmp_mappings["<S-Tab>"] = nil

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
end

cmp.setup({
  performance = {
    trigger_debounce_time = 1000,
  },
  snippet = {
    expand = function(args)
      -- For `luasnip` user.
      require("luasnip").lsp_expand(args.body)
    end,
  },
  window = {
    completion = cmp.config.window.bordered(),
  },
})

lsp.setup_nvim_cmp({
  mapping = cmp_mappings,
  sources = cmp_sources,
  formatting = cmp_formatting,
})

lsp.set_preferences({
  suggest_lsp_servers = false,
  sign_icons = {
    error = "",
    warn = "",
    hint = "",
    info = "",
  },
})

-- " nnoremap <silent> <leader>rn <cmd>lua vim.lsp.buf.rename()<CR>
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

lsp.setup()

vim.diagnostic.config({
  virtual_text = true,
})

require("cmp_git").setup()
