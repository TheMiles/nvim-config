-----------------------------------------------------------
-- Plugin manager installer
-----------------------------------------------------------
--
-- Plugin manager: lazy.nvim
-- url: https://github.com/folke/lazy.nvim
--
-- This file makes sure our package manager lazy.vim is available
-- you need to require this before any other plugin stuff is done
--
-- Returns true if lazy.nvim can be used, false otherwise
-- (e.g. no git or no network on this host)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  if vim.fn.executable("git") == 0 then
    return false
  end
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    return false
  end
end
vim.opt.rtp:prepend(lazypath)

return true
