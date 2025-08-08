return {
  {
    "dsych/blanket.nvim",
    opts = {
      report_path = vim.fn.getcwd() .. "/core/target/site/jacoco/jacoco.xml",
      signs = {
        priority = 10,
        incomplete_branch = "█",
        uncovered = "█",
        covered = "█",
        sign_group = "Blanket",

        -- and the highlights for each sign!
        -- useful for themes where below highlights are similar
        incomplete_branch_color = "WarningMsg",
        covered_color = "Statement",
        uncovered_color = "Error",
      },
    },
    keys = {
      { "<leader>cb", group = "Coverage" },
      { "<leader>cbs", ":lua require'blanket'.start()<CR>", desc = "Display Code Coverage Gutter" },
      { "<leader>cbS", ":lua require'blanket'.stop()<CR>", desc = "Mask Code Coverage Gutter" },
      { "<leader>cbr", ":lua require'blanket'.refresh()<CR>", desc = "Refresh Code Coverage Gutter" },
    },
  },
}
