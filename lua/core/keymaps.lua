-----------------------------------------------------------
--  Generic keybindings
-----------------------------------------------------------
--
-- Only bindings that work without plugins live here.
-- Bindings for a plugin are defined in its file in lua/plugins.
--
-- <leader> is space, groups by first letter:
--   f  find

-----------------------------------------------------------
-- Functions to ease addition of new keybindings
-----------------------------------------------------------

-- desc is shown in the which-key menu and in the keymap search
local function map(mode, shortcut, command, desc)
    vim.keymap.set(mode, shortcut, command, { silent = true, desc = desc })
end

local function nmap(shortcut, command, desc)
    map('n', shortcut, command, desc)
end

local function imap(shortcut, command, desc)
    map('i', shortcut, command, desc)
end

local function vmap(shortcut, command, desc)
    map('v', shortcut, command, desc)
end

local function tmap(shortcut, command, desc)
    map('t', shortcut, command, desc)
end

-----------------------------------------------------------
--  Editing
-----------------------------------------------------------

imap('jk', '<esc>', 'Leave insert mode')
tmap('jk', '<C-\\><C-n>', 'Leave terminal mode')

vmap('>', '>gv', 'Indent and keep selection')
vmap('<', '<gv', 'Unindent and keep selection')

nmap('<esc>', '<cmd>nohlsearch<CR>', 'Clear search highlight')

-----------------------------------------------------------
--  Buffers and windows
-----------------------------------------------------------

nmap('<S-h>', '<cmd>bprevious<CR>', 'Previous buffer')
nmap('<S-l>', '<cmd>bnext<CR>', 'Next buffer')

nmap('<C-h>', '<C-w>h', 'Window left')
nmap('<C-j>', '<C-w>j', 'Window below')
nmap('<C-k>', '<C-w>k', 'Window above')
nmap('<C-l>', '<C-w>l', 'Window right')

-----------------------------------------------------------
--  Help
-----------------------------------------------------------

nmap('<leader>h', function()
    vim.cmd.view(vim.fn.stdpath('config') .. '/CHEATSHEET.md')
end, 'Cheat sheet')
