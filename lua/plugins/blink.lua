-----------------------------------------------------------
--
-- Configuration for blink.cmp
-- completion menu while typing
--
-----------------------------------------------------------

-- Tab accepts, Enter always inserts a new line (super-tab preset).
-- Snippets come from friendly-snippets and run on neovim's own
-- snippet engine.

return {
  'saghen/blink.cmp',
  version = '1.*', -- release builds ship a prebuilt fuzzy matcher
  lazy = false, -- loads its parts lazily itself
  dependencies = { 'rafamadriz/friendly-snippets' },
  opts = {
    keymap = { preset = 'super-tab' },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    completion = { documentation = { auto_show = true } },
    -- without the prebuilt matcher (offline host) use the lua one, silently
    fuzzy = { implementation = 'prefer_rust' },
  },
}
