return {
  {
    "nvim-mini/mini.statusline",
    version = "*",
    event = "VeryLazy",
    -- config = statusline_config,
    config = function()
      require("mini.statusline").setup()
    end,
  },
}
