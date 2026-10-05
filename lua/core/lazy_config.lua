-----------------------------------------------------------
-- Plugin manager configuration file
-----------------------------------------------------------
--
-- Plugin manager: lazy.nvim
-- url: https://github.com/folke/lazy.nvim
--
-- This file is the main configuration for the package manager

local env = require('core.env')
local lang = require('core.lang')

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
    -- plugins only a single language needs, see lua/lang
    lang.collect('plugins'),
  },
  defaults = {
    -- plugins can be switched off per host in lua/local.lua
    cond = function(plugin)
      return env.plugin_enabled(plugin.name)
    end,
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
