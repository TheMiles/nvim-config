-----------------------------------------------------------
-- Plugin manager configuration file
-----------------------------------------------------------
--
-- Plugin manager: lazy.nvim 
-- url: https://github.com/folke/lazy.nvim
--
-- This file is the main configuration for the package manager


-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})

