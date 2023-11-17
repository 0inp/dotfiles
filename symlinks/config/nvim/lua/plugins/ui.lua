return {
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    keys = {
      { "<Tab>", "<Cmd>BufferLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        -- separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },
  -- animations
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.scroll = {
        enable = false,
      }
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<C-H>", "<cmd>TmuxNavigateLeft<cr>", "Move to left window" },
      { "<C-J>", "<cmd>TmuxNavigateDown<cr>", "Move to down window" },
      { "<C-K>", "<cmd>TmuxNavigateUp<cr>", "Move to up window" },
      { "<C-L>", "<cmd>TmuxNavigateRight<cr>", "Move to right window" },
    },
  },
}
