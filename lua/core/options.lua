-----------------------------------------------------------
--  Options file 
-----------------------------------------------------------

local g   = vim.g
local opt = vim.opt


-----------------------------------------------------------
-- General
-----------------------------------------------------------

opt.clipboard      = 'unnamedplus' -- use system clipboard

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

-- for compatibility reasons /bin is linked to /usr/bin
-- thus when checking for python3 executable it shows
-- up twice. So telling neovim which one is the 
-- 'correct' one
g.python3_host_prog = '/usr/bin/python3'

-- disable looking for per provider
g.loaded_perl_provider = 0


-----------------------------------------------------------
-- Plugin derived options
-----------------------------------------------------------

-- disable internal file explore to not interfere with nvim-tree
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1

