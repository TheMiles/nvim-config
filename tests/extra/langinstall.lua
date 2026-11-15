-- runs :LangInstall against a stubbed mason registry, like mason
-- calls back: refresh fails in a fast event context (offline host),
-- then refresh works but every install fails
local registry = require('mason-registry')

local function from_fast_event(fn)
  local timer = vim.uv.new_timer()
  timer:start(10, 0, function()
    timer:close()
    fn()
  end)
end

local function wait_for_message(text)
  vim.wait(1000, function()
    return vim.fn.execute('messages'):find(text, 1, true) ~= nil
  end, 20)
end

registry.refresh = function(callback)
  from_fast_event(function()
    callback(false)
  end)
end
vim.cmd.LangInstall()
wait_for_message('LangInstall:')

registry.refresh = function(callback)
  from_fast_event(function()
    callback(true)
  end)
end
registry.get_package = function(name)
  return {
    name = name,
    is_installed = function()
      return false
    end,
    is_installing = function()
      return name == 'clangd'
    end,
    install = function(_, _, callback)
      from_fast_event(function()
        callback(false, 'no npm')
      end)
    end,
  }
end
vim.cmd.LangInstall()
wait_for_message('ruff failed')
