-----------------------------------------------------------
--
-- Configuration for nvim-tree
-- a file explorerer
--
-----------------------------------------------------------


-- get help with :help nvim-tree.setup
-- help for specific options help: nvim-tree.option

return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup {
        renderer = {
          highlight_git = true,
          highlight_opened_files = "all",
          highlight_modified = "all",
        },
        update_focused_file = {
          enable = true,
        },
        diagnostics = {
          enable = true,
        },
        modified = {
          enable = true,
        },
    }

    -- helper to close nvim-tree if it is the last buffer
    -- taken from this discussion:
    -- https://github.com/nvim-tree/nvim-tree.lua/issues/1005#issuecomment-1183468091

    local modifiedBufs = function(bufs)
      local t = 0
      for k,v in pairs(bufs) do
        if v.name:match("NvimTree_") == nil then
          t = t + 1
        end
      end
      return t
    end

    vim.api.nvim_create_autocmd("BufEnter", {
      nested = true,
      callback = function()
        if #vim.api.nvim_list_wins() == 1 and
          vim.api.nvim_buf_get_name(0):match("NvimTree_") ~= nil and
          modifiedBufs(vim.fn.getbufinfo({bufmodified = 1})) == 0 then
          vim.cmd "quit"
        end
      end
    })

    -- Function to handle nvim opening behavior
    -- Open the nvim-tree when nvim opens a dir
    -- more information here: https://github.com/nvim-tree/nvim-tree.lua/wiki/Open-At-Startup

    local function open_nvim_tree(data)

      -- buffer is a directory
      local directory = vim.fn.isdirectory(data.file) == 1

      if not directory then
        return
      end

      -- change to the directory
      vim.cmd.cd(data.file)

      -- open the tree
      require("nvim-tree.api").tree.open()
    end

    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
  end,
}
