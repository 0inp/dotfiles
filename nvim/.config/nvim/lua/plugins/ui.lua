--: lualine
vim.pack.add({
	"https://github.com/nvim-lualine/lualine.nvim",
})

require("lualine").setup({
	sections = {
		lualine_x = {
			{
				"lsp_status",
				symbols = {
					-- Standard unicode symbols to cycle through for LSP progress:
					spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
					-- Standard unicode symbol for when LSP is done:
					done = "✓",
					-- Delimiter inserted between LSP names:
					separator = " ",
				},
				-- List of LSP names to ignore (e.g., `null-ls`):
				ignore_lsp = {},
				-- Display the LSP name
				show_name = true,
			},
			{ "filetype" },
		},
	},
	inactive_sections = {
		lualine_c = {
			{ "filename", path = 1, file_status = true },
		},
	},
})
--:

----: bufferline
vim.pack.add({
	{ src = "https://github.com/akinsho/nvim-bufferline.lua" },
})

require("bufferline").setup({
	options = {
		mode = "buffers",
		separator_style = "thin",
		show_buffer_close_icons = true,
		show_close_icon = true,
	},
})
--:

--: gitsigns
vim.pack.add({
	"https://github.com/lewis6991/gitsigns.nvim", -- git signs
}, { confirm = false })

require("gitsigns").setup()
--:

--: window navigation
-- Replaces nvim-tmux-navigation, which existed only to hand these keys off to
-- tmux. Same bindings, now plain window commands.
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
vim.keymap.set("n", "<C-\\>", "<C-w>p", { desc = "Go to last active window" })
vim.keymap.set("n", "<C-Space>", "<C-w>w", { desc = "Cycle to next window" })
--:
