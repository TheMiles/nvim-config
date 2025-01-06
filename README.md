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
* [Keymaps](#keymaps)
* [General](#general)
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
luarocks
```
## Nerdfonts

Make sure to install and enable [Nerd Fonts](https://www.nerdfonts.com/)

# Structure

* `init.lua` - main configuration file, used to only reference other config files
* `lua` - Containing all the lua stuff
  * `core` - All main configuration files
    * `options.lua` - Config options for vim and neovim
    * `keymaps.lua` - All keybindings, generic and specific for plugins
    * `lazy_config.lua` - enabling of used plugins. For details see [section about plugins](#plugins)

# Keymaps

* To exit *insert* or *terminal* mode, you can also use `jk`
* `>`, `<` for indentation in *visual* mode
* `Shift-h`, `Shift-l` to switch between buffers
* `Ctrl-Left`, `Ctrl-Right` switch between windows (specifically treeview)

## Searching

* `/` invoke incremental search
* `n` move to next match
* `N` move to previous match
* `C-p` fzf a file
* `C-\` fzf open buffers
* `C-l` do a live grep (using rg)
* `C-k` search available keymaps

## Insert register

In *insert* or *command* mode you can insert content of a register by pressing `C-r <register_name>` where [register_name](#registers) is the according key. 

## Cheat sheet

### Move cursor

| Key | Does what | Key | Does what  |
|-----|-----------|-----|------------|
| `h` | Move left | `l` | Move right |
| `j` | Move down | `k` | Move up    |

### Move horizontally

| Key    | Does what                        | Key | Does what             |
|--------|----------------------------------|-----|-----------------------|
| `0`    | Move to line start               | `$` | Move to line end      |
| `^`    | Move to first non blank char     | `e` | Move to end of word   |
| `w`    | Move to next word                | `b` | Move to previous word | 
| `F<c>` | Move to next occurrence of `<c>` |     |                       |

### Move vertically

| Key        | Does what                                       | Key        | Does what               |
|------------|-------------------------------------------------|------------|-------------------------|
| `(`        | Move up one sentence                            | `)`        | Move down one sentence  |
| `{`        | Move up one paragraph                           | `}`        | Move down one paragraph |
| `ctrl + u` | Move up half a page                             | `ctrl + d` | Move down half a page   |
| `ctrl + b` | ~Move up a page~ overriden by opening tree view | `ctrl + f` | Move down a page        |
| `gg`       | Move to buffer start                            | `G`        | Move to end of buffer   |

### Insert mode

| Key   | Does what                           | Key   | Does what                                   |
|-------|-------------------------------------|-------|---------------------------------------------|
| `i`   | Insert before cursor                | `I`   | Insert at start of line (before first char) |
|       |                                     | `I`   | *In vertical select* multi edit             |
| `a`   | Insert after cursor                 | `A`   | Insert after end of line                    |
| `o`   | Insert new line in next line        | `O`   | Insert new line in previous line            |
| `C`   | Clear from cursor until end of line | `ciw` | Change current word                         |
| `s`   | Clear symbol under cursor           | `S`   | Clear line                                  |
| `J`   | Join next line                      |       |                                             |
| `r`   | Replace character under cursor      | `~`   | Change case of character under cursor       |
| `gUw` | Change word to uppercase            | `guw` | Change word to lowercase                    |
### Copy paste

| Key         | Does what                                     | Key   | Does what                                                        |
|-------------|-----------------------------------------------|-------|------------------------------------------------------------------|
| `y<n>y`     | Yank `<n>` lines (if n is omitted, 1 line)    | `yw`  | Yank to start of next word                                       |
| `y^`        | Yank until start of line                      | `y$`  | Yank until end of line                                           |
| `yiw`       | Yank current word                             | `yi{` | Yank current region enclosed by `{}`, could also be `()` or `[]` |
| `yt<c>`     | Yank until next occurence of `<c>`            |       |                                                                  |
| `d<n>d`     | Delete `<n>` lines (if n is omitted 1 line)   |       | Remaining shortcuts are similar to yanking                       |
| `p`         | Paste *unnamed* register in line after cursor | `P`   | Paste *unnamed* register in line before cursor                   |
| `ctrl + v ` | Enter visual select mode                      |       |                                                                  |

### History

| Key | Does what          | Key        | Does what |
|-----|--------------------|------------|-----------|
| `u` | Undo               | `ctrl + r` | Redo      |
| `.` | Repeat last action |            |           |

### Searching

| Key | Does what                                  | Key | Does what                                       |
|-----|--------------------------------------------|-----|-------------------------------------------------|
| `/` | Invoke incremental serch                   |     |                                                 |
| `n` | Move to next match                         | `N` | Move to previous match                          |
| `*` | Search next occurence of word under cursor | `#` | Search previous occurrence of word under cursor |

### Bookmark

| Key     | Does what                            | Key        | Does what                              |
|---------|--------------------------------------|------------|----------------------------------------|
| `m<c>`  | Bookmark position of cursor in `<c>` | `` `<c> `` | Return to position bookmarked in `<c>` |
| `` ` `` | Toggle between last two positions    | `` `. ``   | Return to last editing                 |

### Coding

| Key     | Does what                         | Key        | Does what                          |
|---------|-----------------------------------|------------|------------------------------------|
| `==`    | Indent current line               | `%`        | Jump to corresponding bracket      |

### Macro

| Key     | Does what                              | Key      | Does what                                |
|---------|----------------------------------------|----------|------------------------------------------|
| `q<c>`  | Record macro in *named* register `<c>` | `@<c>`   | Recall macro from *named* register `<c>` |

### Commands

| Key              | Does what                             | Key                | Does what                                   |
|------------------|---------------------------------------|--------------------|---------------------------------------------|
| `:s/<pattern>/<substitute>/` | Replace occurrence of `<pattern>` with `<substitute>` (once per line) | `:%s/<pattern>/<substitute>/` | Replace occurrences of `<pattern>` with `<substitute>` (several per line) |
| `:g/<pattern>/d` | Delete all lines matching `<pattern>` | `:v/<pattern>/d`   | Delete all lines *not* matching `<pattern>` |
| `:'<'> <...>`    | Apply `<...>` to current selection    |                    |                                             |
| `:read <path>`   | Read file into current buffer         | `:read !<command>` | Read output of command in current buffer    |
| `:sort`          | Sort lines in file                    | `:sort!`           | Sort lines in file descending               |


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
Here you cna enable plugins by adding them to a list.
If you need specific configuration for a plugin, you can also
create a file in `lua/plugins/...`.

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

```
```

### nvim-web-devicons

[`nvim-web-devicons`](https://github.com/nvim-tree/nvim-web-devicons) adds filetype glyphs and colors.

### feline

[`feline`](https://github.com/feline-nvim/feline.nvim) a minimal, stylish and customizable statusline

### fzf-lua

[`fzf-lua`](https://github.com/ibhagwan/fzf-lua) lua implementation for using fzf

Some [general introduction about fzf on YT](https://www.youtube.com/watch?v=qgG5Jhi_Els)

Shortcuts

* `C-p` Search for files
* `C-\` Search for buffers
* `C-g` Grep - search for grep expression and then interactively search the results
* `C-l` Live grep - interactively search for grep expression
* `C-k` Keymaps

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

