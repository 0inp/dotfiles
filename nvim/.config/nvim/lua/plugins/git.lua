return {
  {
    "nvim-mini/mini-git",
    dependencies = { "nvim-mini/mini.notify" },
    version = "*",
    event = "VeryLazy",
    config = function()
      require("mini.git").setup()
    end,
  },
}
