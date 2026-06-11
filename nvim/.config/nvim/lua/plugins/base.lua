vim.pack.add({
	"https://github.com/nvim-mini/mini.nvim",
	"https://github.com/rafamadriz/friendly-snippets",
	"https://github.com/tpope/vim-fugitive",
})

-- mini files ----
local MiniFiles = require("mini.files")
MiniFiles.setup({
	mappings = {
		go_in = "<CR>",
		go_in_plus = "L",
		go_out = "_",
		go_out_plus = "H",
	},
	windows = {
		preview = true,
	},
})

vim.keymap.set("n", "-", "<cmd>lua MiniFiles.open()<CR>", { desc = "Toggle mini file explorer" })
vim.keymap.set("n", "<leader>-", function()
	MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
	MiniFiles.reveal_cwd()
end, { desc = "Toggle into currently opened file" })

local show_dotfiles = true

local filter_show = function(fs_entry)
	return true
end

local filter_hide = function(fs_entry)
	return not vim.startswith(fs_entry.name, ".")
end

local toggle_dotfiles = function()
	show_dotfiles = not show_dotfiles
	local new_filter = show_dotfiles and filter_show or filter_hide
	MiniFiles.refresh({ content = { filter = new_filter } })
end

vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(args)
		local buf_id = args.data.buf_id
		-- Tweak left-hand side of mapping to your liking
		vim.keymap.set("n", "g.", toggle_dotfiles, { buffer = buf_id })
	end,
})

local map_split = function(buf_id, lhs, direction)
	local rhs = function()
		-- Make new window and set it as target
		local cur_target = MiniFiles.get_explorer_state().target_window
		local new_target = vim.api.nvim_win_call(cur_target, function()
			vim.cmd(direction .. " split")
			return vim.api.nvim_get_current_win()
		end)

		MiniFiles.set_target_window(new_target)

		-- This intentionally doesn't act on file under cursor in favor of
		-- explicit "go in" action (`l` / `L`). To immediately open file,
		-- add appropriate `MiniFiles.go_in()` call instead of this comment.
	end

	-- Adding `desc` will result into `show_help` entries
	local desc = "Split " .. direction
	vim.keymap.set("n", lhs, rhs, { buffer = buf_id, desc = desc })
end

vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(args)
		local buf_id = args.data.buf_id
		-- Tweak keys to your liking
		map_split(buf_id, "<C-s>", "belowright horizontal")
		map_split(buf_id, "<C-v>", "belowright vertical")
		map_split(buf_id, "<C-t>", "tab")
	end,
})

local set_mark = function(id, path, desc)
	MiniFiles.set_bookmark(id, path, { desc = desc })
end
vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesExplorerOpen",
	callback = function()
		set_mark("d", "~/dotfiles", "Dotfiles")
		set_mark("~", "~", "Home directory")
	end,
})

---- mini notify ----
require("mini.notify").setup({
	-- only show messages
	content = {
		format = function(notif)
			return notif.msg
		end,
	},
})

--- mini cmdline completion ---
require("mini.cmdline").setup({
	autocorrect = { enable = false },
})

--- mini surround ---
require("mini.surround").setup()
-- Default Keymaps
-- | `sa` | Add surrounding or Direct with 'saiw' |
-- | `sd` | Delete surrounding |
-- | `sr` | Replace surrounding |
-- | `sf` | Find surrounding (right) |
-- | `sF` | Find surrounding (left) |
-- | `sh` | Highlight surrounding |
-- | `sn` | Update n_lines |
-- | `l` / `n` | as suffix for prev/next |
--

--- mini a/i text objects extension ---
require("mini.ai").setup()

--- mini a/i text objects extension ---
require("mini.indentscope").setup()

--- mini a/i text objects extension ---
require("mini.pairs").setup()

--- mini picker ---
local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")
MiniPick.setup()
MiniExtra.setup()

-- keymaps
vim.keymap.set("n", "<leader>pf", function()
	MiniPick.builtin.files()
end, { desc = "Mini File Picker" })
vim.keymap.set("n", "<leader>ps", function()
	MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word/Search word" })
vim.keymap.set("n", "<leader>vh", function()
	MiniPick.builtin.help()
end, { desc = "Mini Help" })

vim.keymap.set("n", "<leader>xx", function()
	MiniExtra.pickers.diagnostic()
end, { desc = "Mini Picker Diagnostics" })
vim.keymap.set("n", "<leader>pk", function()
	MiniExtra.pickers.keymaps()
end, { desc = "Search keymaps" })

--- mini completions ---
require("mini.completion").setup({
	lsp_completion = {
		auto_setup = true,
	},
})

--- mini snippets ---
local MiniSnippets = require("mini.snippets")
MiniSnippets.setup({
	snippets = {
		MiniSnippets.gen_loader.from_lang(), -- loads friendly-snippets
	},
})
MiniSnippets.start_lsp_server({ match = false })
