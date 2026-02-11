-- Override leap.nvim configuration to fix deprecated warnings
-- This is a temporary fix for https://github.com/LazyVim/LazyVim/issues/6958
-- Can be removed once LazyVim updates to use the new Codeberg URL
return {
  {
    "ggandor/leap.nvim",
    -- Keep using the original repository for now to avoid authentication issues
    -- The repository moved warning will still appear but functionality is preserved
    dependencies = {
      { "ggandor/leap-spooky.nvim" },
    },
    config = function()
      -- Import leap
      local leap = require("leap")
      
      -- Set up modern key mappings instead of deprecated add_default_mappings()
      -- These are the recommended mappings from leap-mappings help
      -- This fixes the "add_default_mappings() is deprecated" warning
      
      -- Forward search (normal, visual, operator-pending modes)
      vim.keymap.set({'n', 'x', 'o'}, 's', function()
        leap.leap { target_windows = vim.tbl_filter(
          function(win) return vim.api.nvim_win_get_config(win).focusable end,
          vim.api.nvim_tabpage_list_wins(0)
        ) }
      end, { desc = "Leap forward to" })
      
      -- Backward search (normal, visual, operator-pending modes)
      vim.keymap.set({'n', 'x', 'o'}, 'S', function()
        leap.leap { target_windows = vim.tbl_filter(
          function(win) return vim.api.nvim_win_get_config(win).focusable end,
          vim.api.nvim_tabpage_list_wins(0)
        ), backward = true }
      end, { desc = "Leap backward to" })
      
      -- Visual mode specific mappings
      vim.keymap.set('x', 'x', function()
        leap.leap { target_windows = vim.tbl_filter(
          function(win) return vim.api.nvim_win_get_config(win).focusable end,
          vim.api.nvim_tabpage_list_wins(0)
        ) }
      end, { desc = "Leap forward to" })
      
      vim.keymap.set('x', 'X', function()
        leap.leap { target_windows = vim.tbl_filter(
          function(win) return vim.api.nvim_win_get_config(win).focusable end,
          vim.api.nvim_tabpage_list_wins(0)
        ), backward = true }
      end, { desc = "Leap backward to" })
      
      -- Repeat search with ; and ,
      vim.keymap.set({'n', 'x', 'o'}, ';', function()
        if vim.v.count > 0 then
          local target = leap.get_last_search({ offset = vim.v.count })
          if target then leap.leap { target = target } end
        else
          leap.leap { target_windows = vim.tbl_filter(
            function(win) return vim.api.nvim_win_get_config(win).focusable end,
            vim.api.nvim_tabpage_list_wins(0)
          ) }
        end
      end, { desc = "Repeat leap forward" })
      
      vim.keymap.set({'n', 'x', 'o'}, ',', function()
        if vim.v.count > 0 then
          local target = leap.get_last_search({ offset = -vim.v.count })
          if target then leap.leap { target = target } end
        else
          leap.leap { target_windows = vim.tbl_filter(
            function(win) return vim.api.nvim_win_get_config(win).focusable end,
            vim.api.nvim_tabpage_list_wins(0)
          ), backward = true }
        end
      end, { desc = "Repeat leap backward" })
      
      -- Notify user about the fix
      vim.notify("Leap.nvim: Fixed deprecated mappings (repository warning may still appear)", vim.log.levels.INFO, {
        title = "Leap Configuration"
      })
    end,
    -- Disable the LazyVim extra to prevent duplicate loading
    enabled = true,
  }
}