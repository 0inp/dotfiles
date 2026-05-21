vim.pack.add({
	"https://github.com/folke/todo-comments.nvim", -- highlight TODO/INFO/WARN comments
	"https://github.com/catgoose/nvim-colorizer.lua", -- css colors colorization
}, { confirm = false })

require("todo-comments").setup()
require("colorizer").setup()
