if true then
  return {
    {
      "neovim/nvim-lspconfig",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = {
        { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
        { "folke/neodev.nvim", opts = {} },
        "mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        {
          "hrsh7th/cmp-nvim-lsp",
          cond = function()
            return require("lazyvim.util").has("nvim-cmp")
          end,
        },
      },
      ---@class PluginLspOpts
      opts = {
        -- options for vim.diagnostic.config()
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = {
            spacing = 4,
            source = "if_many",
            prefix = "●",
            -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
            -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
            -- prefix = "icons",
          },
          severity_sort = true,
        },
        -- add any global capabilities here
        capabilities = {},
        -- Automatically format on save
        autoformat = true,
        -- Enable this to show formatters used in a notification
        -- Useful for debugging formatter issues
        format_notify = true,
        -- options for vim.lsp.buf.format
        -- `bufnr` and `filter` is handled by the LazyVim formatter,
        -- but can be also overridden when specified
        format = {
          formatting_options = nil,
          timeout_ms = nil,
        },
        -- LSP Server Settings
        ---@type lspconfig.options
        servers = {
          pylsp = {
            enabled = { true },
            settings = {
              -- configurationSources = { "flake8" },
              plugins = {
                ruff = {
                  enabled = false,
                  extendSelect = { "I" },
                  extendIgnore = { "E501" },
                },
                pyflakes = { enabled = false },
                pycodestyle = { enabled = false },
                flake8 = { enabled = false },
                mypy = {
                  enabled = true,
                  live_mode = true,
                  strict = true,
                },
              },
            },
          },
          jsonls = {},
          lua_ls = {
            -- mason = false, -- set to false if you don't want this server to be installed with mason
            settings = {
              Lua = {
                workspace = {
                  checkThirdParty = false,
                },
                completion = {
                  callSnippet = "Replace",
                },
              },
            },
          },
        },
        -- you can do any additional lsp server setup here
        -- return true if you don't want this server to be setup with lspconfig
        ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
        setup = {
          -- example to setup with typescript.nvim
          -- tsserver = function(_, opts)
          --   require("typescript").setup({ server = opts })
          --   return true
          -- end,
          -- Specify * to use this function as a fallback for any server
          -- ["*"] = function(server, opts) end,
        },
      },
      ---@param opts PluginLspOpts
      config = function(_, opts)
        local Util = require("lazyvim.util")
        -- setup autoformat
        require("lazyvim.plugins.lsp.format").setup(opts)
        -- setup formatting and keymaps
        Util.on_attach(function(client, buffer)
          require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
        end)

        -- diagnostics
        for name, icon in pairs(require("lazyvim.config").icons.diagnostics) do
          name = "DiagnosticSign" .. name
          vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
        end

        if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
          opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
            or function(diagnostic)
              local icons = require("lazyvim.config").icons.diagnostics
              for d, icon in pairs(icons) do
                if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                  return icon
                end
              end
            end
        end

        vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

        local servers = opts.servers
        local capabilities = vim.tbl_deep_extend(
          "force",
          {},
          vim.lsp.protocol.make_client_capabilities(),
          require("cmp_nvim_lsp").default_capabilities(),
          opts.capabilities or {}
        )

        local function setup(server)
          local server_opts = vim.tbl_deep_extend("force", {
            capabilities = vim.deepcopy(capabilities),
          }, servers[server] or {})

          if opts.setup[server] then
            if opts.setup[server](server, server_opts) then
              return
            end
          elseif opts.setup["*"] then
            if opts.setup["*"](server, server_opts) then
              return
            end
          end
          require("lspconfig")[server].setup(server_opts)
        end

        -- get all the servers that are available thourgh mason-lspconfig
        local have_mason, mlsp = pcall(require, "mason-lspconfig")
        local all_mslp_servers = {}
        if have_mason then
          all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
        end

        local ensure_installed = {} ---@type string[]
        for server, server_opts in pairs(servers) do
          if server_opts then
            server_opts = server_opts == true and {} or server_opts
            -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
            if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
              setup(server)
            else
              ensure_installed[#ensure_installed + 1] = server
            end
          end
        end

        if have_mason then
          mlsp.setup({ ensure_installed = ensure_installed, handlers = { setup } })
        end

        if Util.lsp_get_config("denols") and Util.lsp_get_config("tsserver") then
          local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
          Util.lsp_disable("tsserver", is_deno)
          Util.lsp_disable("denols", function(root_dir)
            return not is_deno(root_dir)
          end)
        end
      end,
    },
  }
end

-- if true then
--   return {
--     {
--       "neovim/nvim-lspconfig",
--       opts = {
--         format_notify = true,
--         servers = {
--           pylsp = {
--             pylsp = {
--               settings = {
--                 -- configurationSources = { "flake8" },
--                 --   -- enabled = { false },
--                 plugins = {
--                   ruff = {
--                     enabled = false,
--                     extendSelect = { "I" },
--                     extendIgnore = { "E501" },
--                   },
--                   pyflakes = { enabled = false },
--                   pycodestyle = { enabled = false },
--                   flake8 = { enabled = false },
--                   mypy = {
--                     enabled = true,
--                     live_mode = true,
--                     strict = true,
--                   },
--                 },
--               },
--             },
--           },
--           -- X will be automatically installed with mason and loaded with lspconfig
--           -- pyright = {},
--           -- ruff_lsp = {},
--           -- jedi_language_server = {},
--           dockerls = {},
--           bashls = {},
--           yamlls = {
--             settings = {
--               yamlVersion = 1.2,
--               keyOrdering = false,
--               validate = false,
--             },
--             -- enabled = { false },
--             schemas = {
--               ["https://raw.githubusercontent.com/quantumblacklabs/kedro/develop/static/jsonschema/kedro-catalog-0.17.json"] = "conf/**/*catalog*",
--               ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
--               ["https://raw.githubusercontent.com/microsoft/azure-pipelines-vscode/master/service-schema.json"] = {
--                 "/azure-pipeline*.y*l",
--                 "/*.azure*",
--                 "Azure-Pipelines/**/*.y*l",
--                 "Pipelines/*.y*l",
--               },
--             },
--           },
--           jsonls = {},
--           html = {},
--           terraformls = {},
--           marksman = {},
--         },
--         setup = {},
--       },
--     },
--   }
-- end
-- -- LSP Zero not working right...
-- return {
--   {
--     "VonHeikemen/lsp-zero.nvim",
--     branch = "v2.x",
--     dependencies = {
--       -- LSP Support
--       { "neovim/nvim-lspconfig" }, -- Required
--       { -- Optional
--         "williamboman/mason.nvim",
--         build = function()
--           pcall(vim.cmd, "MasonUpdate")
--         end,
--       },
--       { "williamboman/mason-lspconfig.nvim" }, -- Optional
--
--       -- Autocompletion
--       { "hrsh7th/nvim-cmp" }, -- Required
--       {
--         "hrsh7th/cmp-nvim-lsp",
--         cond = function()
--           return require("lazyvim.util").has("nvim-cmp")
--         end,
--       }, -- Required
--       { "L3MON4D3/LuaSnip" }, -- Required
--     },
--     config = function()
--       local lsp = require("lsp-zero")
--       lsp.extend_lspconfig()
--       -- lsp.preset({})
--
--       lsp.on_attach(function(client, bufnr)
--         lsp.default_keymaps({ buffer = bufnr })
--       end)
--
--       local lspconfig = require("lspconfig")
--       -- lspconfig.lua_ls.setup(lsp.nvim_lua_ls())
--
--       -- lsp.setup()
--
--       lsp.configure("pylsp", {
--         settings = {
--           pylsp = {
--             -- configurationSources = { "flake8" },
--             enabled = { false },
--             plugins = {
--               ruff = {
--                 enabled = false,
--                 Select = { "I" },
--                 extendIgnore = { "E501" },
--               },
--               pyflakes = { enabled = false },
--               pycodestyle = { enabled = false },
--               flake8 = { enabled = false },
--               mypy = {
--                 enabled = true,
--                 live_mode = true,
--                 strict = true,
--               },
--               -- jedi_completion = { fuzzy = true, enabled = true },
--               -- jedi_hover = { enabled = true },
--               -- jedi_references = { enabled = true },
--               -- jedi_signature_help = { enabled = true },
--               -- jedi_symbols = { enabled = true, all_scopes = true },
--             },
--           },
--         },
--       })
--     end,
--   },
-- }
