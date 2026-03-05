vim.pack.add({
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim" },
})

local builtin = require("telescope.builtin")

require("telescope").setup({
	pickers = {
		buffers = {
			initial_mode = "normal",
		},
	},
})

vim.keymap.set("n", "<C-p>", builtin.find_files, {})
vim.keymap.set("n", "gb", ":Telescope buffers<CR>", { desc = "[G]oto [B]uffer" })
vim.keymap.set("n", "<leader>ss", builtin.lsp_dynamic_workspace_symbols, { desc = "[S]earch [S]ymbols" })
vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch [G]rep" })
vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[S]earch [B]uffer" })
vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
vim.keymap.set("n", "<leader>sq", builtin.quickfix, { desc = "[S]earch [Q]uickfix" })
vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
