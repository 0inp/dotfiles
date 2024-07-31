return {
  {
    "folke/noice.nvim",
    opts = {
      routes = {
        {
          view = "notify",
          filter = { event = "msg_showmode" },
        },
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    opts = {
      render = "compact",
      stages = "fade",
      top_down = false,
    },
  },
}
