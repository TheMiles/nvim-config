-----------------------------------------
--
--
-- neovim configuration file
--
--
-----------------------------------------

-- Core stuff
-- make sure to load plugins first
require('core.plugins')
require('core.options')
require('core.keymaps')
require('core.colors')

-- Plugin configuration

require('plugins.nvim-tree')
require('plugins.feline')

