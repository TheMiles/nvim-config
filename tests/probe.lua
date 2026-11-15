-----------------------------------------------------------
--  Probe for tests/run.sh
-----------------------------------------------------------
--
-- Loaded with --cmd before the config, so it can watch the startup.
-- After startup it prints what a user would observe as KEY=VALUE
-- lines on stdout and quits. run.sh compares these lines.
--
-- Environment:
--   PROBE_FT      comma separated filetypes to open, reports highlighting
--   PROBE_OLD_NVIM  if set, pretend neovim is older than 0.12
--   PROBE_EXTRA   lua file run after startup, reports with probe_put(key, value)

if vim.env.PROBE_OLD_NVIM then
  local has = vim.fn.has
  vim.fn.has = function(feature)
    if feature == 'nvim-0.12' then
      return 0
    end
    return has(feature)
  end
end

-- count calls to nvim-treesitter's install()
local ts_install_calls = 0
local orig_require = require
_G.require = function(name)
  local m = orig_require(name)
  if name == 'nvim-treesitter' and type(m) == 'table' and not m.__probed then
    local install = m.install
    m.install = function(...)
      ts_install_calls = ts_install_calls + 1
      return install(...)
    end
    m.__probed = true
  end
  return m
end

local done = false

local function check()
  if done then
    return
  end
  done = true

  local out = {}
  local function put(k, v)
    out[#out + 1] = k .. '=' .. tostring(v)
  end

  put('lazy_loaded', package.loaded['lazy'] ~= nil)
  put('mapleader', vim.g.mapleader)

  local maps = {
    { 'n', '<C-h>' }, { 'n', '<C-j>' }, { 'n', '<C-k>' }, { 'n', '<C-l>' },
    { 'i', 'jk' }, { 'n', '<C-p>' }, { 'n', '<C-b>' },
    { 'n', '<leader>ff' }, { 'n', '<leader>fg' }, { 'n', '<leader>fG' },
    { 'n', '<leader>fb' }, { 'n', '<leader>fk' },
    { 'n', '<leader>cd' },
  }
  for _, m in ipairs(maps) do
    local d = vim.fn.maparg(m[2], m[1], false, true)
    local state = 'no'
    if next(d) then
      state = (d.desc and d.desc ~= '') and 'desc' or 'nodesc'
    end
    put('map ' .. m[1] .. ' ' .. m[2], state)
  end

  put('clipboard', vim.g.clipboard and vim.g.clipboard.name or 'none')
  if vim.g.clipboard then
    vim.fn.setreg('', 'probe')
    local r = vim.g.clipboard.paste['+']()
    put('paste', type(r) == 'table' and r[1][1] or 'error')
  end

  for _, p in ipairs({ 'python3', 'ruby', 'node', 'perl' }) do
    put('provider ' .. p, vim.g['loaded_' .. p .. '_provider'])
  end

  if package.loaded['core.lang'] then
    local lang = require('core.lang')
    put('parsers', table.concat(lang.collect('treesitter'), ','))
    put('servers', table.concat(lang.collect('servers'), ','))
    put('mason', table.concat(lang.collect('mason'), ','))
    if lang.collect_map then
      local formatters = lang.collect_map('formatters')
      local fts = vim.tbl_keys(formatters)
      table.sort(fts)
      for _, ft in ipairs(fts) do
        put('formatter ' .. ft, table.concat(formatters[ft], ','))
      end
    end
  end

  if package.loaded['lazy'] then
    local plugins = require('lazy.core.config').plugins
    for _, n in ipairs({ 'fzf-lua', 'nvim-tree.lua', 'which-key.nvim', 'nvim-treesitter' }) do
      put('plugin ' .. n, plugins[n] and 'loaded' or 'off')
    end
  end

  put('ts_install_calls', ts_install_calls)

  for _, ft in ipairs(vim.split(vim.env.PROBE_FT or '', ',', { trimempty = true })) do
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(buf)
    local ok = pcall(function()
      vim.bo[buf].filetype = ft
    end)
    local state = vim.treesitter.highlighter.active[buf] and 'on' or 'off'
    put('highlight ' .. ft, ok and state or 'error')
  end

  if vim.env.PROBE_EXTRA then
    _G.probe_put = put
    local ok, err = pcall(dofile, vim.env.PROBE_EXTRA)
    if not ok then
      put('extra_error', err)
    end
  end

  -- messages shown to the user during startup, one per line
  for _, line in ipairs(vim.split(vim.trim(vim.fn.execute('messages')), '\n', { trimempty = true })) do
    put('message', line)
  end

  io.stdout:write(table.concat(out, '\n') .. '\n')
  vim.cmd('qa!')
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  once = true,
  callback = function()
    vim.defer_fn(check, 300)
  end,
})
-- the fallback mode has no VeryLazy event
vim.api.nvim_create_autocmd('VimEnter', {
  once = true,
  callback = function()
    vim.defer_fn(check, 2000)
  end,
})
