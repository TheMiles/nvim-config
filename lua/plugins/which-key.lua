-----------------------------------------------------------
--
-- Configuration for which-key
-- shows the available keybindings after pressing <leader>
--
-----------------------------------------------------------

return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    -- names of the groups, see lua/core/keymaps.lua
    spec = {
      { '<leader>f', group = 'find' },
      { '<leader>c', group = 'code' },
      { '<leader>u', group = 'toggles' },
    },
  },
}
