local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight yanked text
local highlight_group = augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
	pattern = "*",
	callback = function()
		vim.hl.on_yank({ timeout = 170 })
	end,
	group = highlight_group,
})

vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

autocmd("BufWinEnter", {
	pattern = "*.jsx,*.tsx",
	group = vim.api.nvim_create_augroup("TS", { clear = true }),
	callback = function()
		vim.cmd([[set filetype=typescriptreact]])
	end,
})
