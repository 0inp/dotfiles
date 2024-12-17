return {
  "folke/edgy.nvim",
  event = "VeryLazy",
  opts = {
    right = {
      {
        title = "File System",
        ft = "neo-tree",
        filter = function(buf)
          return vim.b[buf].neo_tree_source == "filesystem"
        end,
        size = { height = 0.5 },
      },
    },
  },
}