return {
  "nvimtools/none-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "mason.nvim" },
  lazy = false,
  opts = function()
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
          "--remove-unused",
          "$FILENAME",
        },
        to_stdin = false,
        to_temp_file = true,
      },
      factory = h.formatter_factory,
    })

    nls.builtins.formatting.ruff = h.make_builtin({
      name = "ruff",
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
    return {
      root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
      sources = {
        -- formatting
        nls.builtins.formatting.stylua,
        nls.builtins.formatting.prettier,
        nls.builtins.formatting.yamlfmt,
        nls.builtins.formatting.sqlformat,
        nls.builtins.formatting.beautysh,
        nls.builtins.formatting.trim_whitespace,
        nls.builtins.formatting.trim_newlines,
        nls.builtins.formatting.json_tool,
        -- nls.builtins.formatting.black.with({ extra_args = { "--fast" } }),
        -- nls.builtins.formatting.tidy_import,
        nls.builtins.formatting.ruff,
        nls.builtins.formatting.isort.with({ extra_args = { "--sl" } }),

        -- diagnostics
        nls.builtins.diagnostics.markdownlint,
        nls.builtins.diagnostics.hadolint,
        -- completions
        -- nls.builtins.completion.spell,

        nls.builtins.code_actions.gitsigns,
        nls.builtins.formatting.terraform_fmt,
        nls.builtins.diagnostics.terraform_validate,
      },
    }
  end,
}
