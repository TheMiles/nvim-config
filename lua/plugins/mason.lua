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

    local function notify(message, level)
      vim.notify('LangInstall: ' .. message, level)
    end

    vim.api.nvim_create_user_command('LangInstall', function()
      local registry = require('mason-registry')
      -- mason may call back from libuv, where most of the api is
      -- not allowed, so run the callbacks in the main loop
      registry.refresh(vim.schedule_wrap(function(success)
        if not success then
          notify('could not update the package list (network?)', vim.log.levels.WARN)
          return
        end
        local missing = 0
        for _, name in ipairs(require('core.lang').collect('mason')) do
          local ok, package = pcall(registry.get_package, name)
          if not ok then
            notify('unknown package ' .. name, vim.log.levels.WARN)
          elseif package:is_installing() then
            notify(name .. ' is already being installed')
          elseif not package:is_installed() then
            missing = missing + 1
            notify('installing ' .. name)
            package:install({}, vim.schedule_wrap(function(installed, err)
              if installed then
                -- servers are looked for at startup only
                notify(name .. ' installed, restart nvim to use it')
              else
                notify(name .. ' failed: ' .. tostring(err), vim.log.levels.WARN)
              end
            end))
          end
        end
        if missing == 0 then
          notify('nothing to install')
        end
      end))
    end, { desc = 'Install servers and tools of all enabled languages' })
  end,
}
