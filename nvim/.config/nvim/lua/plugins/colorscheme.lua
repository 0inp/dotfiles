vim.pack.add({
	{ src = "https://github.com/loctvl842/monokai-pro.nvim", name = "monokai" },
})

require("monokai-pro").setup({
	transparent_background = true,
})

vim.cmd.colorscheme("monokai-pro-ristretto")

