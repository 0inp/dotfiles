--: nvim-notify
vim.pack.add({
	{ src = "https://github.com/rcarriga/nvim-notify" },
	{ src = "https://github.com/MunifTanjim/nui.nvim" },
	{ src = "https://github.com/folke/noice.nvim" },
})
require("noice").setup({
	lsp = {
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
		},
	},
	presets = {
		bottom_search = true, -- use a classic bottom cmdline for search
		command_palette = true, -- position the cmdline and popupmenu together
		long_message_to_split = true, -- long messages will be sent to a split
		inc_rename = false, -- enables an input dialog for inc-rename.nvim
		lsp_doc_border = false, -- add a border to hover docs and signature help
	},
})
--:

--: nvim-tree
vim.pack.add({
	{ src = "https://github.com/nvim-tree/nvim-tree.lua" },
})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
vim.keymap.set("n", "<leader>e", vim.cmd.NvimTreeToggle, { desc = "Tree" })
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
	{ src = "https://github.com/nvim-lualine/lualine.nvim" },
})

require("lualine").setup({
	options = {
		theme = "auto",
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = {
			{
				"branch",
				fmt = function(str)
					if #str > 5 then
						return str:sub(1, 5) .. "…"
					end
					return str
				end,
			},
			"diff",
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				file_status = true,
				fmt = function(str)
					local sep = package.config:sub(1, 1) -- Get OS-specific path separator ('/' or '\')
					local parts = {}

					for part in string.gmatch(str, "([^" .. sep .. "]+)") do
						table.insert(parts, part)
					end

					-- If there's only one part (the filename), just return it
					if #parts == 1 then
						return parts[1]
					end

					local result = {}
					-- Process all parts except the last one
					for i = 1, #parts - 1 do
						-- Take the first character of the directory name
						table.insert(result, parts[i]:sub(1, 1))
					end

					-- Add the full filename (the last part)
					table.insert(result, parts[#parts])

					-- Join them all back together
					return table.concat(result, sep)
				end,
			},
		},
		lualine_x = { "diagnostics", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	tabline = {
		--lualine_a = { 'tabs' }
	},
	inactive_sections = {
		lualine_c = { { "filename", path = 1, file_status = true } },
	},
	extensions = {},
})
--:

----: bufferline
vim.pack.add({
	{ src = "https://github.com/akinsho/nvim-bufferline.lua" },
	-- Optional, but recommended for file icons
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
		{ "<leader>s", group = "[S]earch", icon = { icon = "", color = "orange" } },
		{ "<leader>p", group = "[P]ack", icon = { icon = "󰏓", color = "blue" } },
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
