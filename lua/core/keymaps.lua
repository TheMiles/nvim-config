-----------------------------------------------------------
--  Gather all the different keybindings
-----------------------------------------------------------

-----------------------------------------------------------
-- Functions to ease addition of new keybindings
-----------------------------------------------------------

local function map(mode, shortcut, command, additional_options)
    local options = { noremap = true, silent = true }
    if additional_options then
        options = vim.tbl_extend('force', options, additional_options)
    end
    vim.api.nvim_set_keymap(mode, shortcut, command, options)
end

local function nmap(shortcut, command, additional_options)
    map('n', shortcut, command, additional_options)
end

local function imap(shortcut, command, additional_options)
    map('i', shortcut, command, additional_options)
end

local function vmap(shortcut, command, additional_options)
    map('v', shortcut, command, additional_options)
end

local function tmap(shortcut, command, additional_options)
    map('t', shortcut, command, additional_options)
end

-----------------------------------------------------------
--  Generic keybindings
-----------------------------------------------------------

imap('jk','<esc>') -- use jk instead of esc
tmap('jk','<C-\\><C-n>') -- use jk to escape terminal

vmap('>','>gv') -- better indentation in visual mode
vmap('<','<gv') -- better indentation in visual mode

nmap('<S-h>',':bprevious<CR>') -- S-h to switch to prev. buffer
nmap('<S-l>',':bnext<CR>')     -- S-l to switch to next buffer


-----------------------------------------------------------
--  Mappings for nvim tree
-----------------------------------------------------------

nmap('<C-b>', ':NvimTreeToggle<CR>')  -- open/close

-----------------------------------------------------------
-- Mappings for fzf-lua 
-----------------------------------------------------------

nmap('<C-p>', ':FzfLua files<CR>') -- fzf with files
nmap('<C-\\>', ':FzfLua buffers<CR>') -- fzf with currently open buffers 
nmap('<C-g>', ':FzfLua grep<CR>') -- call rg
nmap('<C-l>', ':FzfLua live_grep<CR>') -- live rg
nmap('<C-k>', ':FzfLua keymaps<CR>') -- fzf in available keymaps

-----------------------------------------------------------
--  
-----------------------------------------------------------
