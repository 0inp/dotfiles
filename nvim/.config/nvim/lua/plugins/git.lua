return {
  {
    "echasnovski/mini-git",
    dependencies = { "echasnovski/mini.notify" },
    version = "*",
    event = "VeryLazy",
    config = function()
      require("mini.git").setup()
    end,
  },
}
