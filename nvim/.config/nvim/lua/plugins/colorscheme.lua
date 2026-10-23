-- Catppuccin Mocha, the theme of the whole setup (ghostty, bat, delta, btop,
-- herdr, lazygit, fzf...). Transparent so ghostty's opacity and blur show
-- through. The integrations for mini, gitsigns, render-markdown and mason are
-- picked up automatically; lualine's "auto" theme follows the colorscheme.
vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
})

require("catppuccin").setup({
	flavour = "mocha",
	transparent_background = true,
})

vim.cmd.colorscheme("catppuccin-mocha")
