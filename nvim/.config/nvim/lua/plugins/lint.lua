return {
  "mfussenegger/nvim-lint",
  optional = true,
  opts = {
    linters_by_ft = {
      terraform = { "terraform_validate" },
      tf = { "terraform_validate" },
    },
  },
}
