return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "ravitemer/mcphub.nvim",
    },
    keys = {
      { "<leader>a", group = "AI" },
      { "<leader>aa", ":CodeCompanionActions<CR>", desc = "Open CodeCompanion Actions" },
      { "<leader>ac", ":CodeCompanionChat Toggle<CR>", desc = "Open CodeCompanion Chat" },
    },
    opts = {
      strategies = {
        chat = {
          adapter = "openai",
        },
        inline = {
          adapter = "openai",
        },
      },
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            make_vars = true,
            make_slash_commands = true,
            show_result_in_chat = true,
          },
        },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
  },
  {
    "echasnovski/mini.diff",
    config = function()
      local diff = require("mini.diff")
      diff.setup({
        -- Disabled by default
        source = diff.gen_source.none(),
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        per_filetype = {
          codecompanion = { "codecompanion" },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        mode = { "n", "v" },
        { "<leader>a", group = "AI" },
      },
    },
  },
}
