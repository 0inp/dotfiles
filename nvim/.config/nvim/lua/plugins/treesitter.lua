vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter" },
})
require("nvim-treesitter").install({
	"javascript",
	"json",
	"lua",
	"markdown",
	"python",
	"query",
	"toml",
	"typescript",
	"vim",
	"vimdoc",
})
require("nvim-treesitter").update()
