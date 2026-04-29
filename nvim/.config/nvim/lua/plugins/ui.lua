require("vim._core.ui2").enable()
vim.opt.completeopt:append("popup")

--: nvim-tree
vim.pack.add({
	{ src = "https://github.com/nvim-tree/nvim-tree.lua" },
})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.keymap.set("n", "<leader>e", vim.cmd.NvimTreeToggle, { desc = "Toggle NvimTree" })
require("nvim-tree").setup({
	view = {
		adaptive_size = true,
		side = "right",
	},
	update_focused_file = {
		enable = true,
	},
	sync_root_with_cwd = true,
	respect_buf_cwd = true,
})
--:

--: lualine
vim.pack.add({
	"https://github.com/nvim-tree/nvim-web-devicons",
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
			{ "venv-selector" },
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
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },
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

--: which-key
vim.pack.add({ "https://github.com/folke/which-key.nvim" }, { confirm = false })

require("which-key").setup({
	spec = {
		{ "<leader>c", group = "[C]ode", icon = { icon = "", color = "green" } },
		{ "<leader>s", group = "[F]ind", icon = { icon = "", color = "orange" } },
		{ "<leader>p", group = "[P]ack", icon = { icon = "󰏓", color = "blue" } },
		{ "<leader>b", group = "[B]uffers navigation" },
	},
})
--:

--: gitsigns
vim.pack.add({
	"https://github.com/lewis6991/gitsigns.nvim", -- git signs
}, { confirm = false })

require("gitsigns").setup()
--:

--: nvim-tmux-navigation
vim.pack.add({
	"https://github.com/alexghergh/nvim-tmux-navigation", -- tmux/nvim navigation
}, { confirm = false })
require("nvim-tmux-navigation").setup({
	disable_when_zoomed = true, -- defaults to false
	keybindings = {
		left = "<C-h>",
		down = "<C-j>",
		up = "<C-k>",
		right = "<C-l>",
		last_active = "<C-\\>",
		next = "<C-Space>",
	},
})
--:
