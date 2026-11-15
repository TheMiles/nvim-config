-----------------------------------------------------------
--
-- Configuration for mason
-- installs language servers and formatters per user, no root needed
--
-----------------------------------------------------------

-- Packages are installed on request only (:LangInstall), so startup
-- needs no network. Installed tools are put on PATH, so the plugins
-- asking core.env find them.

return {
  'mason-org/mason.nvim',
  lazy = false, -- other plugins look for its tools at startup
  config = function()
    require('mason').setup()

    vim.api.nvim_create_user_command('LangInstall', function()
      local registry = require('mason-registry')
      registry.refresh(function()
        for _, name in ipairs(require('core.lang').collect('mason')) do
          local ok, package = pcall(registry.get_package, name)
          if not ok then
            vim.notify('LangInstall: unknown package ' .. name, vim.log.levels.WARN)
          elseif not package:is_installed() then
            vim.notify('LangInstall: installing ' .. name)
            package:install()
          end
        end
      end)
    end, { desc = 'Install servers and tools of all enabled languages' })
  end,
}
