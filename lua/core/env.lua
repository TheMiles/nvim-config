-----------------------------------------------------------
--  What is available on this host
-----------------------------------------------------------
--
-- Plugins and languages ask this module before they load anything.
-- Defaults can be overridden per host in lua/local.lua,
-- see lua/local.lua.example

local M = {}

local overrides = { plugins = {}, langs = {} }

local path = vim.fn.stdpath('config') .. '/lua/local.lua'
if vim.uv.fs_stat(path) then
  local ok, result = pcall(dofile, path)
  if ok and type(result) == 'table' then
    overrides = vim.tbl_deep_extend('force', overrides, result)
  else
    vim.notify('lua/local.lua ignored: ' .. tostring(result), vim.log.levels.WARN)
  end
end

-- true when running inside a ssh session
M.ssh = vim.env.SSH_TTY ~= nil

-- is the external program available
function M.has(executable)
  return vim.fn.executable(executable) == 1
end

-- name is the plugin name as shown in :Lazy, e.g. 'nvim-tree.lua'
function M.plugin_enabled(name)
  return overrides.plugins[name] ~= false
end

-- name is the file name in lua/lang without extension, e.g. 'python'
function M.lang_enabled(name)
  return overrides.langs[name] ~= false
end

return M
