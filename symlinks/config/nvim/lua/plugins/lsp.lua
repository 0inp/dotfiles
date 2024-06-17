return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "shellcheck",
      "shfmt",
      "mypy",
    },
  },
  {
    -- https://github.com/brenoprata10/nvim-highlight-colors
    "brenoprata10/nvim-highlight-colors",
    config = function()
      require("nvim-highlight-colors").setup({})
    end,
  },
}
