# nvim-config

In this repo I want to keep my neo vim config.
It might evolve over time, let's see.
Currently I'm just playing around. So don't expect
anything functional here....

And right at the moment I'm moving my current setup from 
init.vim to completely using lua. So at the beginning
it will be a downgrade. Stuff is heavily influenced by
[neovim configuration from brainfuck](https://github.com/brainfucksec/neovim-lua)


# Content

* [Installation](#installation)
* [Resources](#resources)

# Installation

## Check health

use `:checkhealth` to get a first overview of the current status of the system.

# Structure

* `init.lua` - main configuration file, used to only reference other config files
* `lua` - Containing all the lua stuff
  * `core` - All main configuration files
    * `options.lua` - Config options for vim and neovim

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

