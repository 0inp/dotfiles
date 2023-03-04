-------------------------------------------------
-- name : telescope
-- url  : https://github.com/nvim-telescope/telescope.nvim
-------------------------------------------------
local M = {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.1',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local actions = require "telescope.actions"
      local telescope = require("telescope")
      telescope.setup({
        extensions = {
          fzf = {
            fuzzy = true,                    -- false will only do exact matching
            override_generic_sorter = true,  -- override the generic sorter
            override_file_sorter = true,     -- override the file sorter
            case_mode = "smart_case",        -- or "ignore_case" or "respect_case"
          }
        },
      })
    end
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make"
  },
}

return M
