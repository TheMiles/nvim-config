# nvim-config

In this repo I want to keep my neo vim config.
It might evolve over time, let's see.
Currently I'm just playing around. So don't expect
anything functional here....

# Installation

## Check health

use `:checkhealth` to get a first overview of the current status of the system.





## Plugin Manager

For loading plugins a plugin manager is used. Specifically [vim-plug](https://github.com/junegunn/vim-plug).

For specific installation information refer to the website. This excerpt is for Unix/Linux:

```
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```

### Adding plugins

To add a plugin add it to the `init.vim` file.

```
Plug 'tpope/vim-sensible'
```

Reload .vimrc and `:PlugInstall` to install plugins.


