return {
  {
    "echasnovski/mini.statusline",
    version = "*",
    event = "VeryLazy",
    -- config = statusline_config,
    config = function()
      require("mini.statusline").setup()
    end,
  },
}
