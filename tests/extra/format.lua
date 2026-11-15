-- saves files in $PROBE_PROJECT and reports their first line;
-- the fake formatters prepend '-- formatted'
local base = vim.env.PROBE_PROJECT

local function save(file)
  vim.cmd.edit(base .. '/' .. file)
  vim.cmd.write()
  return vim.fn.readfile(base .. '/' .. file)[1]
end

probe_put('save with config', save('with-config/a.lua'))
probe_put('save without config', save('without-config/a.lua'))
probe_put('save pyproject with ruff', save('ruff-project/a.py'))
probe_put('save pyproject without ruff', save('other-project/a.py'))
-- saving never notifies, even when a formatter is missing
-- (let scheduled notifications arrive first)
vim.wait(200)
probe_put('messages after saves', #vim.split(vim.trim(vim.fn.execute('messages')), '\n', { trimempty = true }))

-- the manual key formats regardless of project configuration
vim.cmd.edit(base .. '/without-config/b.lua')
vim.cmd.normal(' cf')
probe_put('manual format', vim.api.nvim_buf_get_lines(0, 0, 1, false)[1])

-- the toggle flips format on save for the session
vim.cmd.normal(' uf')
probe_put('save after toggle', save('with-config/c.lua'))
