# nvim-config

In this repo I keep my neovim config. The goal is a complete IDE,
built in stages. The plan and all decisions are in
[docs/prd-ide.md](docs/prd-ide.md), the daily workflows in the
[cheat sheet](CHEATSHEET.md).

Stuff is heavily influenced by
[neovim configuration from brainfucksec](https://github.com/brainfucksec/neovim-lua)


# Content

* [Installation](#installation)
* [Structure](#structure)
* [Hosts](#hosts)
* [Keymaps](#keymaps)
* [General](#general)
* [Plugins](#plugins)
* [Resources](#resources)


# Installation

Needed neovim version >=**0.12**. With an older version only options and
keymaps are loaded, see [Hosts](#hosts).

Clone this repo to `~/.config/nvim` and start nvim. Plugins are installed
on first start, in the versions pinned in `lazy-lock.json`.

## Check health

use `:checkhealth` to get a first overview of the current status of the system.

## Packages

Some specific packages should be present on the system. Everything
except `git` is optional, the features needing it are skipped if it is missing.

```
git
tree-sitter-cli (>= 0.26.1, not from npm) and a C compiler - to install syntax parsers
fzf, ripgrep - for searching files and text
```
## Nerdfonts

Make sure to install and enable [Nerd Fonts](https://www.nerdfonts.com/)
in the terminal you are sitting at.

## Clipboard over ssh

In a ssh session yanked text is sent to the clipboard of the local terminal
(OSC 52). For this to work

* tmux on the host needs `set -g set-clipboard on`
* iTerm2 needs *Settings > General > Selection > Applications in terminal may access clipboard*

Pasting from the local clipboard is done with the paste of the terminal.

# Structure

* `init.lua` - main configuration file, used to only reference other config files
* `CHEATSHEET.md` - how to get things done, open with `Space h`
* `lazy-lock.json` - the plugin versions in use, kept in git so every host gets the same
* `docs` - the plan
* `lua` - Containing all the lua stuff
  * `core` - All main configuration files
    * `options.lua` - Config options for vim and neovim
    * `keymaps.lua` - Keybindings that work without plugins
    * `lazy_install.lua`, `lazy_config.lua` - The plugin manager. For details see [section about plugins](#plugins)
    * `env.lua` - What is available on this host
    * `lang.lua` - Collects the language files
    * `colors.lua` - Colorscheme
  * `plugins` - One file per plugin, with its configuration and its keybindings
  * `lang` - One file per language, listing everything this language needs
  * `local.lua` - Settings for a single host, not in git. See `local.lua.example`

To add a language, add a file to `lua/lang`. Currently a language file
lists the syntax parsers to install (`treesitter`) and plugins only this
language needs (`plugins`).

# Hosts

The config runs on different hosts, some of them with missing tools.
What is loaded is decided in three steps

1. neovim older than 0.12 or no plugin manager (no `git`, no network):
   only options and keymaps, builtin colorscheme
2. Plugins written in lua only are always loaded
3. Features needing an external tool are loaded if the tool is there,
   otherwise they are skipped silently

To switch off single plugins or languages on one host copy
`lua/local.lua.example` to `lua/local.lua` and edit it.

# Keymaps

`<leader>` is `Space`, `<localleader>` is `,`. After pressing `Space` a menu
shows the available keys. They are grouped by their first letter, for
now there is `f` for find.

All workflows and keys are listed in the [cheat sheet](CHEATSHEET.md).

# General 

## Register

vim offers several different registers. They are either automatically or explicitly filled. 

They can be accessed by prepending `"` to the register name. For example you are in *visual* mode 
and want to yank the current selection to the *named register* e, then you would enter `"ey`.

To read from the register in *insert* or *command* mode you can use `C-r <register_name>`

These are the different register names:

* `"` The *unnamed* register. Contains last yanked/deleted region (if not specifically writing to named register or black hole)
* `-` the last small delete (smaller than a line)
* `_` The black hole. Anything you write to this register is lost.
* `0`-`9` Numbered register. Yank/delete fills according region in `0` and shifts previous content by one *number*
* `a`-`z`, `A`-`Z` *named* registers. Can be used to store something in it.
* `%` **read only** Current filename with full path
* `#` alternate filename (the previous file in this buffer, if applicable)
* `*` or `+` clipboard
* `/` Last search pattern
* `:` **read only** Last command line
* `.` **read only** Last inserted text (Does *not* work with `C-r` on command line)
* `=` The *expression* register. All subsequent inputs until `<CR>` (or `<ESC>`) are evaluated as a command (or abandoned) 

# Plugins

For handling plugins the [lazy plugin manager](https://github.com/folke/lazy.nvim) is used.
The basic setup should happen automatically.

The overall configuration is handled in `lua/core/lazy_config.lua`.
To add a plugin create a file in `lua/plugins/...` containing
its configuration and its keybindings.

* `:Lazy health` equal to `:checkhealth lazy` get details about any problems with the packager.
* `:Lazy` show lazy panel
* `:Lazy help` help text
* `:Lazy install` install missing packages
* `:Lazy clean` remove unused packages
* `:Lazy update` gets updates for packages
* `:Lazy sync` calls install, clean, update
* `:Lazy log` show changelog for packages

## Specific plugins

### nvim-tree

[`nvim-tree`](https://github.com/nvim-tree/nvim-tree.lua) is a file explorer. 
Making it easier to browse the available files

Shortcuts

* `C-b` open/close the tree
* `g?` Show help
* `a`  add file or directory
* `q`  close
* `x`  cut
* `p`  paste
* `<C-t>` Open in new tab
* `<C-v>` Open in vertical split
* `<C-x>` Open in horizontal split

### nvim-web-devicons

[`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons) adds filetype glyphs and colors.

### fzf-lua

[`fzf-lua`](https://github.com/ibhagwan/fzf-lua) lua implementation for using fzf

Some [general introduction about fzf on YT](https://www.youtube.com/watch?v=qgG5Jhi_Els)

Shortcuts

* `C-p`, `Space f f` Search for files
* `Space f b` Search for buffers
* `Space f G` Grep - search for grep expression and then interactively search the results
* `Space f g` Live grep - interactively search for grep expression
* `Space f k` Keymaps

### nvim-treesitter

[`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) installs syntax parsers,
used for highlighting and indentation. The parsers are listed per language in `lua/lang`.

* `:TSUpdate` update the installed parsers
* `:checkhealth nvim-treesitter` which parsers are installed

### which-key

[`which-key`](https://github.com/folke/which-key.nvim) shows the available keybindings while typing them.

## Interesting plugins to check

* [`yanky`](https://github.com/gbprod/yanky.nvim) The aim of `yanky.nvim` is to improve yank and put functionalities for Neovim.


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

