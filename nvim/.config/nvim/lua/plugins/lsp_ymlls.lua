return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      format_notify = true,
      servers = {
        yamlls = {
          -- Have to add this for yamlls to understand that we support line folding
          capabilities = {
            textDocument = {
              foldingRange = {
                dynamicRegistration = false,
                lineFoldingOnly = true,
              },
            },
          },
          -- -- lazy-load schemastore when needed
          -- on_new_config = function(new_config)
          --   new_config.settings.yaml.schemas = vim.tbl_deep_extend(
          --     "force",
          --     new_config.settings.yaml.schemas or {},
          --     require("schemastore").yaml.schemas()
          --   )
          -- end,
          settings = {
            schemas = {
              -- GH Actions
              -- ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
              ["/Users/npayne81/dotfiles/avant/.avant-hidden-though-stowed/github-workflow.json"] = {
                "/.github/workflows/*",
              },
              -- DBT stuff
              ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/dbt_yml_files.json"] = {
                "/staging/**/*.yml",
                "/intermediate/**/*.yml",
                "/marts/**/*.yml",
                "!profiles.yml",
                "!dbt_project.yml",
                "!packages.yml",
                "!selectors.yml",
                "!profile_template.yml",
              },
              ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/dbt_project.json"] = {
                "dbt_project.yml",
              },
              ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/selectors.json"] = {
                "selectors.yml",
              },
              ["https://raw.githubusercontent.com/dbt-labs/dbt-jsonschema/main/schemas/packages.json"] = {
                "packages.yml",
              },
            },
            ["http://json.schemastore.org/ansible-stable-2.9"] = { "roles/tasks/*.{yml,yaml}" },
            ["http://json.schemastore.org/ansible-playbook"] = { "*ansible*.{yml,yaml}" },
            ["http://json.schemastore.org/chart"] = { "Chart.{yml,yaml}" },
            ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = {
              "*docker-compose*.{yml,yaml}",
            },
            ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = {
              "*flow*.{yml,yaml}",
            },
          },
        },
      },
    },
    setup = {},
  },
}
