# nvim-config

In this repo I want to keep my neo vim config.
It might evolve over time, let's see.
Currently I'm just playing around. So don't expect
anything functional here....

And right at the moment I'm moving my current setup from 
init.vim to completely using lua. So at the beginning
it will be a downgrade. Stuff is heavily influenced by
[neovim configuration from brainfucksec(https://github.com/brainfucksec/neovim-lua)


# Content

* [Installation](#installation)
* [Structure](#structure)
* [Plugins](#plugins)
* [Resources](#resources)


# Installation

Needed neovim version >=**0.8.0**

## Check health

use `:checkhealth` to get a first overview of the current status of the system.

## Packages

Some specific packages should be present on the system

```
python3
ruby
git
```
## Nerdfonts

Make sure to install and enable [Nerd Fonts](https://www.nerdfonts.com/)

# Structure

* `init.lua` - main configuration file, used to only reference other config files
* `lua` - Containing all the lua stuff
  * `core` - All main configuration files
    * `options.lua` - Config options for vim and neovim
    * `keymaps.lua` - All keybindings, generic and specific for plugins
    * `plugins.lua` - enabling of used plugins. For details see [section about plugins](#plugins)

# Plugins

For handling plugins the [packer plugin manager](https://github.com/wbthomason/packer.nvim) is used.
The basic setup should happen automatically.

The overall configuration is handled in `lua/core/plugins.lua`. Here you enable all the plugins by adding them to the list. Specific configuration for each plugin is supposed to be done in separate files in `lua/plugins/...`.

Whenever you make changes to the plugins configuration you have to run `:PackerCompile`. 
Here is a list of different commands provided by packer:

```lua
-- You must run this or `PackerSync` whenever you make changes to your plugin configuration
-- Regenerate compiled loader file
:PackerCompile

-- Remove any disabled or unused plugins
:PackerClean

-- Clean, then install missing plugins
:PackerInstall

-- Clean, then update and install plugins
-- supports the `--preview` flag as an optional first argument to preview updates
:PackerUpdate

-- Perform `PackerUpdate` and then `PackerCompile`
-- supports the `--preview` flag as an optional first argument to preview updates
:PackerSync

-- Show list of installed plugins
:PackerStatus

-- Loads opt plugin immediately
:PackerLoad completion-nvim ale
```

## Specific plugins

### nvim-tree

[`nvim-tree`](https://github.com/nvim-tree/nvim-tree.lua) is a file explorer. 
Making it easier to browse the available files

Shortcuts

```
```

### nvim-web-devicons

[`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons) adds filetype glyphs and colors.

# Resources

## neovim

* [nvim](https://neovim.io/doc/user/index.html) - Documentation main page
* [nvim lua](https://neovim.io/doc/user/lua.html) - Lua documentation by neovim project
* [vim diff](https://neovim.io/doc/user/vim_diff.html) - Differences between nvim and vim
* [Options](https://neovim.io/doc/user/options.html#option-summary) - Neovim's options listed 

## Cheat sheets

* [vim cheat sheet](https://deep-filament-1f1.notion.site/Vim-c4d0e6bcf35b45cbb9d24d9eebd19d71) - Standard vim cheat sheet, grouped by different modes. Done by Kethqwerty in Notion
* [Keyboard layout](https://docs.google.com/spreadsheets/d/15k_UgeY0C3j8tVQnR2hD_kNljB1AApG3x3gYrKtUAlw/edit#gid=1082709605) - A cheat sheet representing all the keys in QWERTY keyboard layout. Done via google docs

## lua

* [Lua in Y minutes](https://learnxinyminutes.com/docs/lua/) - Quick one page overview about lua
* [Quick guide](https://github.com/medwatt/Notes/blob/main/Lua/Lua_Quick_Guide.ipynb) - Another guide 

