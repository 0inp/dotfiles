--: tiny-inline-diagnostic
vim.pack.add({
	{ src = "https://github.com/rachartier/tiny-inline-diagnostic.nvim" },
})
require("tiny-inline-diagnostic").setup()
--- @param diagnostic? vim.Diagnostic
--- @param bufnr integer
local function on_jump(diagnostic, bufnr)
	if not diagnostic then
		return
	end
	vim.diagnostic.show(
		diagnostic.namespace,
		bufnr,
		{ diagnostic },
		{ virtual_lines = { current_line = true }, virtual_text = false }
	)
end
vim.diagnostic.config({
	virtual_text = false,
	jump = { on_jump = on_jump },
})
--:

--: todo-comments, css colors colorization
vim.pack.add({
	"https://github.com/folke/todo-comments.nvim", -- highlight TODO/INFO/WARN comments
	"https://github.com/norcalli/nvim-colorizer.lua", -- css colors colorization
}, { confirm = false })

require("todo-comments").setup()
require("colorizer").setup()
--:

--: mini.nvim plugin suits
vim.pack.add({
	"https://www.github.com/echasnovski/mini.nvim",
})
require("mini.ai").setup()
require("mini.surround").setup()
require("mini.indentscope").setup()
require("mini.pairs").setup()
--:
