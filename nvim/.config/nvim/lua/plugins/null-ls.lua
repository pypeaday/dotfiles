return {
  "nvimtools/none-ls.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "mason.nvim" },
  enabled = false,
  lazy = false,
  opts = function(_, opts)
    local nls = require("null-ls")

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
      nls.builtins.formatting.json_tool,
      nls.builtins.formatting.jq,
      -- nls.builtins.formatting.lua_ls,

      -- diagnostics
      nls.builtins.diagnostics.markdownlint,
      nls.builtins.diagnostics.hadolint,

      nls.builtins.code_actions.proselint,

      -- completions
      nls.builtins.completion.spell,

      nls.builtins.code_actions.gitsigns,
    })
  end,
}
