return {
  "stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  enabled = true,
  formatters_by_ft = {
    -- Use the "_" filetype to run formatters on filetypes that don't
    -- have other formatters configured.
    ["_"] = { "trim_whitespace", "trim_newlines" },
  },
}
