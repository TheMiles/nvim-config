-----------------------------------------------------------
--
-- Language servers
-- enables the servers the language files list, see lua/lang
--
-----------------------------------------------------------

-- nvim-lspconfig is only used for its server configs (lsp/*.lua),
-- the servers are started by neovim itself (vim.lsp.enable).
-- A server is enabled only when its program is installed.

return {
  'neovim/nvim-lspconfig',
  lazy = false, -- servers must be enabled before the first file opens
  dependencies = {
    'mason-org/mason.nvim', -- puts installed servers on PATH
    'saghen/blink.cmp',     -- completion capabilities for the servers
  },
  config = function()
    local env = require('core.env')

    -- tell the servers what the completion plugin can do
    local ok, blink = pcall(require, 'blink.cmp')
    if ok then
      vim.lsp.config('*', { capabilities = blink.get_lsp_capabilities() })
    end

    for _, name in ipairs(require('core.lang').collect('servers')) do
      local cmd = (vim.lsp.config[name] or {}).cmd
      -- a cmd given as a function can't be checked, trust it
      if type(cmd) == 'function' or (type(cmd) == 'table' and env.has(cmd[1])) then
        vim.lsp.enable(name)
      end
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        local function map(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
        end
        map('gd', vim.lsp.buf.definition, 'Go to definition')
        map('<leader>ca', vim.lsp.buf.code_action, 'Code action')
        map('<leader>cr', vim.lsp.buf.rename, 'Rename symbol')
      end,
    })
  end,
}
