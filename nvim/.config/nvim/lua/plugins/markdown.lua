-- Filename: ~/github/dotfiles-latest/neovim/neobean/lua/plugins/headlines.lua
-- ~/github/dotfiles-latest/neovim/neobean/lua/plugins/headlines.lua

-- https://github.com/lukas-reineke/headlines.nvim
-- This already comes installed with lazyvim but I modify the heading colors and
-- also the lines above and below
-- It also adds these { "◉", "○", "✸", "✿" } symbols in headings

return {
  "MeanderingProgrammer/markdown.nvim",
  opts = {
    file_types = { "markdown", "norg", "rmd", "org", "vimwiki" },
    heading = {
      sign = true,
      icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      -- The 'level' is used to index into the array using a clamp
      -- Highlight for the heading icon and extends through the entire line
      backgrounds = {
        "RenderMarkdownH1Bg",
        "RenderMarkdownH2Bg",
        "RenderMarkdownH3Bg",
        "RenderMarkdownH4Bg",
        "RenderMarkdownH5Bg",
        "RenderMarkdownH6Bg",
      },
      -- The 'level' is used to index into the array using a clamp
      -- Highlight for the heading and sign icons
      foregrounds = {
        "RenderMarkdownH1",
        "RenderMarkdownH2",
        "RenderMarkdownH3",
        "RenderMarkdownH4",
        "RenderMarkdownH5",
        "RenderMarkdownH6",
      },
    },
  },
  config = function()
    require("render-markdown").setup(opts)
    LazyVim.toggle.map("<leader>um", {
      name = "Render Markdown",
      get = function()
        return require("render-markdown.state").enabled
      end,
      set = function(enabled)
        local m = require("render-markdown")
        if enabled then
          m.enable()
        else
          m.disable()
        end
      end,
    })
    vim.cmd([[highlight RenderMarkdownH1 guifg=#f1fc79]])
    vim.cmd([[highlight RenderMarkdownH2 guifg=#37f499]])
    vim.cmd([[highlight RenderMarkdownH3 guifg=#04d1f9]])
    vim.cmd([[highlight RenderMarkdownH4 guifg=#f16c75]])
    vim.cmd([[highlight RenderMarkdownH5 guifg=#7081d0]])
    vim.cmd([[highlight RenderMarkdownH6 guifg=#f265b5]])

    vim.cmd([[highlight RenderMarkdownH1Bg guifg=#f1fc79 guibg=#A2A951]])
    vim.cmd([[highlight RenderMarkdownH2Bg guifg=#37f499 guibg=#056136]])
    vim.cmd([[highlight RenderMarkdownH3Bg guifg=#04d1f9 guibg=#025464]])
    vim.cmd([[highlight RenderMarkdownH4Bg guifg=#f16c75 guibg=#960D16]])
    vim.cmd([[highlight RenderMarkdownH5Bg guifg=#7081d0 guibg=#1E295D]])
    vim.cmd([[highlight RenderMarkdownH6Bg guifg=#f265b5 guibg=#960D5B]])

    vim.cmd([[highlight RenderMarkdownCode guibg=#292929]])
  end,
}
--
--     -- Defines the codeblock background color to something darker
--     vim.cmd([[highlight CodeBlock guibg=#09090d]])
--     -- When you add a line of dashes with --- this specifies the color, I'm not
--     -- adding a "guibg" but you can do so if you want to add a background color
--     vim.cmd([[highlight Dash guifg=white]])
--
--     -- Setup headlines.nvim with the newly defined highlight groups
--     require("headlines").setup({
--       markdown = {
--         -- If set to false, headlines will be a single line and there will be no
--         -- "fat_headline_upper_string" and no "fat_headline_lower_string"
--         fat_headlines = false,
--         --
--         -- Lines added above and below the header line makes it look thicker
--         -- "lower half block" unicode symbol hex:2584
--         -- "upper half block" unicode symbol hex:2580
--         fat_headline_upper_string = "▄",
--         fat_headline_lower_string = "▀",
--         --
--         -- You could add a full block if you really like it thick ;)
--         -- fat_headline_upper_string = "█",
--         -- fat_headline_lower_string = "█",
--         --
--         -- Other set of lower and upper symbols to try
--         -- fat_headline_upper_string = "▃",
--         -- fat_headline_lower_string = "-",
--         --
--         headline_highlights = {
--           "Headline1",
--           "Headline2",
--           "Headline3",
--           "Headline4",
--           "Headline5",
--           "Headline6",
--         },
--
--         bullets = { "󰎤", "󰎧", "󰎪", "󰎭", "󰎱", "󰎳" },
--         -- bullets = { "󰎤", "󰎧", "󰎪", "󰎮", "󰎰", "󰎵" },
--         -- bullets = { "◉", "○", "✸", "✿" },
--       },
--     })
--   end,
-- }
