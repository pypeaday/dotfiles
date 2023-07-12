return {
  "nvimtools/none-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "mason.nvim" },
  enabled = true,
  lazy = false,
  init = function()
    local Util = require("lazyvim.util")
    Util.on_very_lazy(function()
      -- register the formatter with LazyVim
      require("lazyvim.util").format.register({
        name = "none-ls.nvim",
        priority = 200, -- set higher than conform, the builtin formatter
        primary = true,
        format = function(buf)
          return Util.lsp.format({
            bufnr = buf,
            filter = function(client)
              return client.name == "null-ls"
            end,
          })
        end,
        sources = function(buf)
          local ret = require("null-ls.sources").get_available(vim.bo[buf].filetype, "NULL_LS_FORMATTING") or {}
          return vim.tbl_map(function(source)
            return source.name
          end, ret)
        end,
      })
    end)
  end,
  opts = function(_, opts)
    local nls = require("null-ls")
    local h = require("null-ls.helpers")
    local methods = require("null-ls.methods")
    local FORMATTING = methods.internal.FORMATTING

    nls.builtins.formatting.tidy_import = h.make_builtin({
      name = "tidy_import",
      meta = {
        url = "https://github.com/deshaw/pyflyby",
        description = "automatic imports for python",
      },
      method = FORMATTING,
      filetypes = { "python" },
      generator_opts = {
        command = "tidy-imports",
        "--quiet",
        args = {
          "--replace-star-imports",
          "--add-missing",
          "--replace",
          "--separate-from-imports",
          -- "--remove-unused",
          "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
      },
      factory = h.formatter_factory,
    })

    nls.builtins.formatting.my_ruff = h.make_builtin({
      name = "my_ruff",
      meta = {
        url = "https://github.com/charliermarsh/ruff",
        description = "Ruff - super fast formatting and linting for Python with Rust",
      },
      method = FORMATTING,
      filetypes = { "python" },
      generator_opts = {
        command = "ruff",
        args = {
          "check",
          "$FILENAME",
          "--fix",
        },
        to_stdin = false,
        to_temp_file = true,
      },
      factory = h.formatter_factory,
    })

    nls.builtins.formatting.jq = h.make_builtin({
      name = "jq",
      meta = {
        description = "Custom shrotcut for jq",
      },
      method = FORMATTING,
      filetypes = { "json" },
      generator_opts = {
        command = "jq",
        args = {
          "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
      },
      factory = h.formatter_factory,
    })

    opts.root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git")
    opts.sources = vim.list_extend(opts.sources or {}, {
      -- formatting
      nls.builtins.formatting.stylua,
      nls.builtins.formatting.prettier,
      -- nls.builtins.formatting.yamlfmt,
      -- avant using yamlfix
      nls.builtins.formatting.yamlfix,
      nls.builtins.formatting.sqlformat,
      nls.builtins.formatting.beautysh,
      nls.builtins.formatting.trim_whitespace,
      nls.builtins.formatting.trim_newlines,
      -- nls.builtins.formatting.json_tool,
      nls.builtins.formatting.jq,
      -- nls.builtins.formatting.lua_ls,
      nls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
      nls.builtins.formatting.tidy_import,
      nls.builtins.formatting.ruff,
      -- nls.builtins.formatting.my_ruff,
      nls.builtins.formatting.isort.with({ extra_args = { "--sl" } }),

      -- diagnostics
      nls.builtins.diagnostics.markdownlint,
      nls.builtins.diagnostics.hadolint,
      nls.builtins.diagnostics.ruff,

      nls.builtins.code_actions.proselint,

      -- completions
      nls.builtins.completion.spell,

      nls.builtins.code_actions.gitsigns,
    })
  end,
}
