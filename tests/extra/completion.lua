-- reports the completion setup as a user would meet it in insert mode
vim.cmd.enew()
vim.api.nvim_exec_autocmds('InsertEnter', { buffer = 0, modeline = false })

-- neovim's own mappings (e.g. <Tab> jumps in snippets) don't count
local function mapped(lhs)
  local map = vim.fn.maparg(lhs, 'i', false, true)
  if not next(map) then
    return 'no'
  end
  return (map.desc or ''):find('vim.snippet', 1, true) and 'default' or 'mapped'
end
probe_put('insert <Tab>', mapped('<Tab>'))
probe_put('insert <CR>', mapped('<CR>'))

local ok, config = pcall(require, 'blink.cmp.config')
probe_put('completion sources', ok and table.concat(config.sources.default, ',') or 'none')
probe_put('lsp completion capabilities',
  vim.lsp.config['*'] and vim.lsp.config['*'].capabilities ~= nil)
