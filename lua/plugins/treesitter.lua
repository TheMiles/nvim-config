-----------------------------------------------------------
--
-- Configuration for nvim-treesitter
-- installs parsers, used for highlighting and indentation
--
-----------------------------------------------------------

-- The parsers to install are listed per language in lua/lang
-- Installing needs the tree-sitter cli and a C compiler. Without
-- them only the parsers shipped with neovim are used.

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- does not support lazy loading
  build = ":TSUpdate",
  config = function()
    local env = require("core.env")

    if env.has("tree-sitter") and (env.has("cc") or env.has("gcc") or env.has("clang")) then
      require("nvim-treesitter").install(require("core.lang").collect("treesitter"))
    end

    -- highlighting and indentation are not enabled automatically,
    -- start them for every filetype we have a parser for
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        local language = vim.treesitter.language.get_lang(args.match)
        if not language or not pcall(vim.treesitter.start, args.buf, language) then
          return
        end
        if vim.treesitter.query.get(language, "indents") then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
