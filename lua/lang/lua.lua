return {
  treesitter = { 'lua', 'luadoc', 'vim', 'vimdoc', 'query' },
  servers = { 'lua_ls' },
  mason = { 'lua-language-server', 'stylua' },
  formatters = { lua = { 'stylua' } },
  format_config = { stylua = { 'stylua.toml', '.stylua.toml' } },
}
