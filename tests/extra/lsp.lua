-- opens one file per language in $PROBE_PROJECT and reports
-- which language servers attached, and the LSP keymaps
for _, file in ipairs({ 'main.c', 'init.lua', 'app.py' }) do
  vim.cmd.edit(vim.env.PROBE_PROJECT .. '/' .. file)
  local buf = vim.api.nvim_get_current_buf()
  vim.wait(1500, function()
    return #vim.lsp.get_clients({ bufnr = buf }) > 0
  end, 50)
  -- a second server of the same file may still be starting
  local count = #vim.lsp.get_clients({ bufnr = buf })
  if count > 0 then
    vim.wait(500, function()
      return #vim.lsp.get_clients({ bufnr = buf }) > count
    end, 50)
  end
  local names = vim.tbl_map(function(c)
    return c.name
  end, vim.lsp.get_clients({ bufnr = buf }))
  table.sort(names)
  probe_put('lsp ' .. file, #names > 0 and table.concat(names, ',') or 'none')
  if file == 'main.c' then
    for _, lhs in ipairs({ 'gd', '<leader>ca', '<leader>cr' }) do
      local map = vim.fn.maparg(lhs, 'n', false, true)
      probe_put('lsp map ' .. lhs, map.buffer == 1 and 'buffer' or 'no')
    end
  end
end

local diag = vim.diagnostic.config()
probe_put('diag virtual_lines.current_line', type(diag.virtual_lines) == 'table' and diag.virtual_lines.current_line)
probe_put('diag virtual_text', diag.virtual_text)
probe_put('diag underline', diag.underline)
probe_put('diag signs', diag.signs ~= false)
