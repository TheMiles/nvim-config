return {
  treesitter = { 'c', 'cpp', 'cmake' },
  servers = { 'clangd' },
  mason = { 'clangd', 'clang-format' },
  formatters = { c = { 'clang-format' }, cpp = { 'clang-format' } },
  format_config = { ['clang-format'] = { '.clang-format', '_clang-format' } },
}
