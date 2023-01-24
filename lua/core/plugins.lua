-----------------------------------------------------------
-- Plugin manager configuration file
-----------------------------------------------------------
--
-- Plugin manager: packer.nvim
-- url: https://github.com/wbthomason/packer.nvim
--
-- This file is the main configuration for the package manager
-- you need to require this before any other plugin stuff is done


-- ensure_packer makes sure packer is installed on the system

local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end

-- so check and install packer, and record whether it has been installed
-- this information is needed at the end of this file
local packer_bootstrap = ensure_packer()


vim.cmd [[
    augroup packer_user_config
        autocmd!
        autocmd BufWritePost plugins.lua source <afile> | PackerCompile
    augroup end
]]

return require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'

    -- My plugins here
    
    -- use 'foo1/bar1.nvim'
    -- use 'foo2/bar2.nvim'
    

    
    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if packer_bootstrap then
        require('packer').sync()
    end
end)