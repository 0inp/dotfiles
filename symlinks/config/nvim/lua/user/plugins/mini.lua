local M = {
  {
    "echasnovski/mini.ai",
    keys = {
      { "a", mode = { "x", "o" } },
      { "i", mode = { "x", "o" } },
    },
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        init = function()
          -- no need to load the plugin, since we only need its queries
          require("lazy.core.loader").disable_rtp_plugin "nvim-treesitter-textobjects"
        end,
      },
    },
    opts = function()
      local ai = require "mini.ai"
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
        },
      }
    end,
    config = function(_, opts)
      local ai = require "mini.ai"
      ai.setup(opts)
    end,
  },
  {
    "echasnovski/mini.animate",
    config = function()
      require("mini.animate").setup()
    end,
  },
  {
    "echasnovski/mini.basics",
    config = function()
      require("mini.basics").setup()
    end,
  },
  {
    "echasnovski/mini.comment",
    config = function()
      require("mini.comment").setup()
    end,
  },
  {
    "echasnovski/mini.fuzzy",
    config = function()
      require("mini.fuzzy").setup()
    end,
  },
  {
    "echasnovski/mini.indentscope",
    config = function()
      require("mini.indentscope").setup()
    end,
  },
  {
    "echasnovski/mini.pairs",
    config = function()
      require("mini.pairs").setup()
    end,
  },
  {
    "echasnovski/mini.starter",
    config = function()
      require("mini.starter").setup({})
    end,
  },
  {
    "echasnovski/mini.surround",
    config = function()
      require("mini.surround").setup()
    end,
  },
  {
    "echasnovski/mini.tabline",
    config = function()
      require("mini.tabline").setup()
    end,
  },
}

return M
