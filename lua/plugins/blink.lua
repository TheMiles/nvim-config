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
    -- the fast matcher is downloaded once; an offline host (see
    -- lua/local.lua) uses the lua matcher, else it would retry and
    -- complain on every start
    fuzzy = require('core.env').offline
        and { implementation = 'lua', prebuilt_binaries = { download = false } }
      or { implementation = 'prefer_rust' },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
    completion = { documentation = { auto_show = true } },
  },
}
