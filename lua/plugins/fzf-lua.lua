-----------------------------------------------------------
--
-- Configuration for fzf-lua
-- fuzzy search for files, text, buffers, ...
--
-----------------------------------------------------------

return {
  'ibhagwan/fzf-lua',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  cmd = 'FzfLua',
  keys = {
    { '<C-p>',      '<cmd>FzfLua files<CR>',     desc = 'Find file' },
    { '<leader>ff', '<cmd>FzfLua files<CR>',     desc = 'Find file' },
    { '<leader>fg', '<cmd>FzfLua live_grep<CR>', desc = 'Grep while typing' },
    { '<leader>fG', '<cmd>FzfLua grep<CR>',      desc = 'Grep, then filter results' },
    { '<leader>fb', '<cmd>FzfLua buffers<CR>',   desc = 'Find open buffer' },
    { '<leader>fk', '<cmd>FzfLua keymaps<CR>',   desc = 'Find keymap' },
  },
}
