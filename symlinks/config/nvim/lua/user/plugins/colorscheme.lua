-------------------------------------------------
-- name : nvim-tree
-- url  : https://github.com/navarasu/onedark.nvim
-------------------------------------------------
local M = {
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    opts = function()
      local colors = require("user.utils").git_colors
      return {
        style = "cool",
        -- hide_inactive_statusline = true,
        on_highlights = function(hl, c)
          hl.GitSignsAdd = {
            fg = colors.GitAdd,
          }
          hl.GitSignsChange = {
            fg = colors.GitChange,
          }
          hl.GitSignsDelete = {
            fg = colors.GitDelete,
          }
        end,
      }
    end,
    config = function(_, opts)
      local onedark = require("onedark")
      onedark.setup(opts)
      onedark.load()
    end,
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    priority = 1000,
    config = function()
      require("rose-pine").setup()
      vim.cmd("colorscheme rose-pine")
    end,
  },
}
return M
