-----------------------------------------
--
--
-- neovim configuration file
--
--
-----------------------------------------

-- Core stuff
-- options and keymaps work on every neovim version,
-- so they are loaded before anything else
require('core.options')
require('core.keymaps')

-- Everything below needs plugins. If this host can't run them,
-- stay with options and keymaps only
local function fallback(reason)
  pcall(vim.cmd.colorscheme, 'habamax')
  vim.api.nvim_echo({ { 'nvim config: ' .. reason .. ', running without plugins', 'WarningMsg' } }, true, {})
end

if vim.fn.has('nvim-0.12') == 0 then
  fallback('neovim >= 0.12 needed')
  return
end

if not require('core.lazy_install') then
  fallback('plugin manager not available')
  return
end

require('core.lazy_config')
require('core.colors')
