return {
  treesitter = { 'lua', 'luadoc', 'vim', 'vimdoc', 'query' },
  servers = { 'lua_ls' },
  mason = { 'lua-language-server', 'stylua' },
  formatters = { lua = { 'stylua' } },
  format_config = { stylua = { 'stylua.toml', '.stylua.toml' } },
  plugins = {
    -- Neovim API typings for lua_ls, only in lua files
    { 'folke/lazydev.nvim', ft = 'lua', opts = {} },
  },
}
