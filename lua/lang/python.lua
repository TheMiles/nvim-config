return {
  treesitter = { 'python' },
  servers = { 'basedpyright', 'ruff' },
  mason = { 'basedpyright', 'ruff' },
  formatters = { python = { 'ruff_format' } },
  format_config = { ruff_format = { 'ruff.toml', '.ruff.toml', { 'pyproject.toml', '[tool.ruff' } } },
}
