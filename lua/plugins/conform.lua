-----------------------------------------------------------
--
-- Configuration for conform.nvim
-- formats code with the formatters the language files list
--
-----------------------------------------------------------

-- On save a file is formatted only if its project carries a
-- configuration for the formatter (e.g. .stylua.toml), so foreign
-- projects are never reformatted by accident. Space c f formats
-- anyway, Space u f switches format on save for the session.

local format_on_save = require('core.env').format_on_save

-- does the file at path contain text
local function contains(path, text)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and table.concat(lines, '\n'):find(text, 1, true) ~= nil
end

-- formatters for buf that are installed and configured in its project
local function project_formatters(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return {}
  end
  local lang = require('core.lang')
  local configs = lang.collect_map('format_config')
  local result = {}
  for _, formatter in ipairs(lang.collect_map('formatters')[vim.bo[buf].filetype] or {}) do
    local info = require('conform').get_formatter_info(formatter, buf)
    for _, marker in ipairs(configs[formatter] or {}) do
      local file, text = marker, nil
      if type(marker) == 'table' then
        file, text = marker[1], marker[2]
      end
      local found = vim.fs.find(file, { path = vim.fs.dirname(name), upward = true })[1]
      if info.available and found and (not text or contains(found, text)) then
        result[#result + 1] = formatter
        break
      end
    end
  end
  return result
end

return {
  'stevearc/conform.nvim',
  event = 'BufWritePre',
  cmd = 'ConformInfo',
  keys = {
    {
      '<leader>cf',
      function()
        require('conform').format({ lsp_format = 'fallback' })
      end,
      desc = 'Format buffer',
    },
    {
      '<leader>uf',
      function()
        format_on_save = not format_on_save
        vim.notify('Format on save: ' .. (format_on_save and 'on' or 'off'))
      end,
      desc = 'Toggle format on save',
    },
  },
  opts = function()
    return {
      formatters_by_ft = require('core.lang').collect_map('formatters'),
      format_on_save = function(buf)
        if not format_on_save then
          return
        end
        local formatters = project_formatters(buf)
        if #formatters == 0 then
          return
        end
        return { formatters = formatters, lsp_format = 'never', timeout_ms = 1000 }
      end,
    }
  end,
}
