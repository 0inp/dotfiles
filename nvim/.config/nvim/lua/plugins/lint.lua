return {
  {
    "mfussenegger/nvim-lint",
    -- opts will be merged with the parent spec
    opts = {
      -- Additional linters can be found here: https://github.com/mfussenegger/nvim-lint#available-linters
      linters_by_ft = {
        python = { "mypy" },
      },
    },
  },
}
