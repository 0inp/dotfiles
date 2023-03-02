--local colorscheme = "kanagawa"
--
--local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
--if not status_ok then
--	return
--end

-- require('onedark').setup {
--     style = 'cool'
-- }
-- require('onedark').load()
-- require("kanagawa").load()
local M = {
  "navarasu/onedark.nvim",
  lazy = false,
  priority = 1000,
  opts = function()
		local colors = require("user.utils").git_colors
		return {
			style = "cool",
			-- hide_inactive_statusline = true,
			on_highlights = function(hl, c)
				hl.GitSignsAdd = {
					fg = colors.GitAdd,
				}
				hl.GitSignsChange = {
					fg = colors.GitChange,
				}
				hl.GitSignsDelete = {
					fg = colors.GitDelete,
				}
			end,
		}
	end,
	config = function(_, opts)
		local onedark = require("onedark")
		onedark.setup(opts)
		onedark.load()
	end,
}
return M
