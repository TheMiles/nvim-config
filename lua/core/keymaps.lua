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


-----------------------------------------------------------
--  Generic keybindings
-----------------------------------------------------------

imap('kj','<esc>') -- use kj instead of esc

-----------------------------------------------------------
--  Mappings for nvim tree
-----------------------------------------------------------

nmap('<C-b>', ':NvimTreeToggle<CR>')  -- open/close

-----------------------------------------------------------
--  
-----------------------------------------------------------
