require("pypeaday.filesystem")
require("pypeaday.telescope")
require("pypeaday.treesitter")
require("pypeaday.lspsaga")
require("pypeaday.lsp-config")

require("pypeaday.cmp")
require("pypeaday.cloak")

P = function(v)
  print(vim.inspect(v))
  return v
end

if pcall(require, 'plenary') then
  RELOAD = require('plenary.reload').reload_module

  R = function(name)
    RELOAD(name)
    return require(name)
  end
end


-- gotta go last
require("pypeaday.color")

