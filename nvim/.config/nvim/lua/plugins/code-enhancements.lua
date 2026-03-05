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

--: autopairs, todo-comments, css colors colorization
vim.pack.add({
	"https://github.com/windwp/nvim-autopairs", -- auto pairs
	"https://github.com/folke/todo-comments.nvim", -- highlight TODO/INFO/WARN comments
	"https://github.com/norcalli/nvim-colorizer.lua", -- css colors colorization
	"https://github.com/kylechui/nvim-surround", -- Add/delete/change surrounding pairs
}, { confirm = false })

require("nvim-autopairs").setup()
require("todo-comments").setup()
require("colorizer").setup()
require("nvim-surround").setup()
--:

--: multicursors
vim.pack.add({
	"https://github.com/jake-stewart/multicursor.nvim",
}, { confirm = false })
local mc = require("multicursor-nvim")
mc.setup()
-- Add or skip cursor above/below the main cursor.
vim.keymap.set({ "n", "x" }, "<up>", function()
	mc.lineAddCursor(-1)
end)
vim.keymap.set({ "n", "x" }, "<down>", function()
	mc.lineAddCursor(1)
end)
vim.keymap.set({ "n", "x" }, "<leader><up>", function()
	mc.lineSkipCursor(-1)
end)
vim.keymap.set({ "n", "x" }, "<leader><down>", function()
	mc.lineSkipCursor(1)
end)

-- Add or skip adding a new cursor by matching word/selection
vim.keymap.set({ "n", "x" }, "<leader>n", function()
	mc.matchAddCursor(1)
end)
vim.keymap.set({ "n", "x" }, "<leader>s", function()
	mc.matchSkipCursor(1)
end)
vim.keymap.set({ "n", "x" }, "<leader>N", function()
	mc.matchAddCursor(-1)
end)
vim.keymap.set({ "n", "x" }, "<leader>S", function()
	mc.matchSkipCursor(-1)
end)

-- Add and remove cursors with control + left click.
vim.keymap.set("n", "<c-leftmouse>", mc.handleMouse)
vim.keymap.set("n", "<c-leftdrag>", mc.handleMouseDrag)
vim.keymap.set("n", "<c-leftrelease>", mc.handleMouseRelease)

-- Disable and enable cursors.
vim.keymap.set({ "n", "x" }, "<c-q>", mc.toggleCursor)

-- Mappings defined in a keymap layer only apply when there are
-- multiple cursors. This lets you have overlapping mappings.
mc.addKeymapLayer(function(layerSet)
	-- Select a different cursor as the main one.
	layerSet({ "n", "x" }, "<left>", mc.prevCursor)
	layerSet({ "n", "x" }, "<right>", mc.nextCursor)

	-- Delete the main cursor.
	layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

	-- Enable and clear cursors using escape.
	layerSet("n", "<esc>", function()
		if not mc.cursorsEnabled() then
			mc.enableCursors()
		else
			mc.clearCursors()
		end
	end)
end)

-- Customize how cursors look.
local hl = vim.api.nvim_set_hl
hl(0, "MultiCursorCursor", { reverse = true })
hl(0, "MultiCursorVisual", { link = "Visual" })
hl(0, "MultiCursorSign", { link = "SignColumn" })
hl(0, "MultiCursorMatchPreview", { link = "Search" })
hl(0, "MultiCursorDisabledCursor", { reverse = true })
hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
--:
