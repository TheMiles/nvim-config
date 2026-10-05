-----------------------------------------------------------
--  Options file 
-----------------------------------------------------------

local g   = vim.g
local opt = vim.opt


-----------------------------------------------------------
-- Leader keys
-----------------------------------------------------------

-- need to be set before any plugin or keymap is loaded
g.mapleader      = ' '   -- <leader> is space
g.maplocalleader = ','   -- <localleader> for filetype specific stuff

-----------------------------------------------------------
-- General
-----------------------------------------------------------

opt.clipboard      = 'unnamedplus' -- use system clipboard

-- In a ssh session there is no system clipboard on the host.
-- Copy to the clipboard of the local terminal using OSC 52.
-- Pasting from the terminal is usually blocked and makes nvim
-- hang, so paste (p) uses what was yanked in nvim. Use the
-- terminal's own paste to insert from the local clipboard.
if vim.env.SSH_TTY and vim.fn.has('nvim-0.10') == 1 then
  local osc52 = require('vim.ui.clipboard.osc52')
  local function paste()
    return { vim.fn.split(vim.fn.getreg(''), '\n'), vim.fn.getregtype('') }
  end
  g.clipboard = {
    name  = 'OSC 52 (copy only)',
    copy  = { ['+'] = osc52.copy('+'), ['*'] = osc52.copy('*') },
    paste = { ['+'] = paste, ['*'] = paste },
  }
end

-----------------------------------------------------------
-- UI
-----------------------------------------------------------

opt.showmatch      = true   -- Show matching parenthesis
opt.number         = true   -- show line numbers
opt.relativenumber = true   -- line numbers show relative distance
opt.cursorline     = false  -- highlight line with cursor
opt.termguicolors  = true   -- enable 24 bit RGB color (needed for nvim-tree) 

-----------------------------------------------------------
-- Behaviour
-----------------------------------------------------------

opt.mouse          = 'a'    -- Enable mouse support (all modes)
opt.wildmode       = 'longest,longest:full' -- commandline completion
                            -- complete longest and present
							-- possible matches
opt.wildignorecase = true   -- ignore case in completion
opt.completeopt    = 'menuone,noinsert' -- autocomplete options
                            -- provide menu even with one entry
							-- insert explicitly

-----------------------------------------------------------
-- Searching
-----------------------------------------------------------

opt.ignorecase     = true   -- Ignore case when searching
opt.hlsearch       = true   -- Highlight search results
opt.incsearch      = true   -- Search while typing
opt.path:remove      "/usr/include" -- remove include dir from
                                    -- search path
opt.path:append      "**"   -- Search recursively in cur dir


-----------------------------------------------------------
-- ignore specific search paths
-----------------------------------------------------------

opt.wildignore:append "**/.git/*"
opt.wildignore:append "**/build/*"

-----------------------------------------------------------
-- tabs, whitespace
-----------------------------------------------------------

opt.tabstop        = 2      -- Number of columns occupied by tab
opt.softtabstop    = 2      -- See multiple spaces as as tabstops
                            -- so <BS> does the right thing
opt.expandtab      = true   -- convert tabs into spaces
opt.shiftwidth     = 2      -- number of spaces to use for indent
opt.autoindent     = true   -- indent new line, to match current line


-----------------------------------------------------------
-- fixing checkhealth
-----------------------------------------------------------

-- no plugin here needs the remote plugin providers,
-- so don't look for them
g.loaded_python3_provider = 0
g.loaded_ruby_provider    = 0
g.loaded_node_provider    = 0
g.loaded_perl_provider    = 0


-----------------------------------------------------------
-- Plugin derived options
-----------------------------------------------------------

-- disable internal file explore to not interfere with nvim-tree
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

