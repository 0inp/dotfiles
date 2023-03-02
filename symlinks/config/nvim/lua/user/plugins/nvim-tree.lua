-------------------------------------------------
-- name : nvim-tree
-- url  : https://github.com/nvim-tree/nvim-tree.lua
-------------------------------------------------
local M = {
	"nvim-tree/nvim-tree.lua",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ "<leader>e", ":NvimTreeToggle<CR>", desc = "Toggle tree" },
	},
  config = true,
}

return M
