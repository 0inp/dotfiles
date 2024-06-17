return {
  "nvim-neo-tree/neo-tree.nvim",
  keys = function()
    return {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ position = "right", reveal = true, toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
    }
  end,
}
