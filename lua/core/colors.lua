vim.g.sonokai_style = 'shusia'
-- fall back to a builtin scheme if sonokai is switched off on this host
if not pcall(vim.cmd.colorscheme, 'sonokai') then
  vim.cmd.colorscheme('habamax')
end
