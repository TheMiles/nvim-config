-----------------------------------------------------------
--  Language support
-----------------------------------------------------------
--
-- Every file in lua/lang describes one language, e.g.
--
--   return {
--     treesitter = { 'python' },   -- parsers to install
--     plugins    = { ... },        -- lazy.nvim specs only this language needs
--   }
--
-- To add a language, add a file there. Plugins ask this module
-- for the combined list of a field over all enabled languages.

local M = {}

local env = require('core.env')

local langs

local function load()
  langs = {}
  for file in vim.fs.dir(vim.fn.stdpath('config') .. '/lua/lang') do
    local name = file:match('^(.+)%.lua$')
    if name and env.lang_enabled(name) then
      local ok, spec = pcall(require, 'lang.' .. name)
      if ok and type(spec) == 'table' then
        langs[name] = spec
      else
        vim.notify('lua/lang/' .. file .. ' ignored: ' .. tostring(spec), vim.log.levels.WARN)
      end
    end
  end
end

-- all entries of a field over all enabled languages, without duplicates
function M.collect(field)
  if not langs then
    load()
  end
  local result, seen = {}, {}
  for _, name in ipairs(vim.fn.sort(vim.tbl_keys(langs))) do
    for _, entry in ipairs(langs[name][field] or {}) do
      if not seen[entry] then
        seen[entry] = true
        result[#result + 1] = entry
      end
    end
  end
  return result
end

return M
