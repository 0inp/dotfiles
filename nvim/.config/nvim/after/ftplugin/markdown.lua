local set = vim.opt_local

set.textwidth = 80 -- move text to new line at 80 characters

-- Spell: fr AND en, not one or the other. A fiche is genuinely bilingual --
-- French prose carrying English technical vocabulary -- so a word is accepted
-- when either dictionary knows it. Picking a single language would underline
-- half of every sentence, which is what `spelllang=en` (the default) did.
--
-- Code needs no special handling here: the markdown treesitter query marks
-- only (inline) as @spell, and markdown_inline marks code spans, link URLs and
-- entity references @nospell. Measured on a mixed file -- a fenced js block,
-- a `codeSpan` and a URL slug raise nothing. This only holds while the
-- treesitter highlighter is attached to the buffer, which plugins/treesitter.lua
-- does from a FileType autocmd.
--
-- fr.utf-8.spl does not ship with Neovim; scripts/install.sh fetches it into
-- ~/.local/share/nvim/site/spell. Without it Neovim flags every French word
-- and prints "Cannot find word list" once per buffer.
set.spelllang = "fr,en"
set.spell = true

-- Split camelCase before checking, so `staleTime` is read as "stale" + "Time"
-- instead of one unknown word. Measured over the nine fiches: 344 -> 321
-- flagged occurrences. Small, but free.
set.spelloptions = "camel"

-- Project dictionary, versioned in this repo (nvim/.config/nvim/spell/).
-- Set explicitly rather than left to the default so it is obvious where `zg`
-- writes: with spelllang=fr,en the default would be the *first* language's
-- .add file, which happens to be the same path -- but only by accident.
--   zg  add the word under the cursor        zug  undo that
--   zw  mark it as wrong                     z=   suggestions
set.spellfile = vim.fn.stdpath("config") .. "/spell/fr.utf-8.add"
set.linebreak = true
set.formatoptions:append("t")
set.smartindent = false

-- Toggle Line Numbers (Visual Selection)
function ToggleNumberVisualSelection()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local lines = vim.fn.getline(start_line, end_line)

	-- Check if any line for numbering
	local has_numbers = false
	for i = 1, #lines do
		if lines[i]:match("^%s*%d+%.%s") then
			has_numbers = true
			break
		end
	end

	if has_numbers then
		-- remove numbers
		for i = 1, #lines do
			lines[i] = lines[i]:gsub("^%s*%d+%.%s*", "")
		end
		print("✓ Numbers removed")
	else
		-- add numbers
		for i = 1, #lines do
			lines[i] = i .. ". " .. lines[i]
		end
		print("✓ Numbers added")
	end

	vim.fn.setline(start_line, lines)
end

-- Toggle Line Numbers for Current Line (Normal Mode)
function ToggleNumberCurrentLine()
	local line_num = vim.fn.line(".")
	local line = vim.fn.getline(line_num)

	if line:match("^%s*%d+%.%s") then
		-- Remove number
		line = line:gsub("^%s*%d+%.%s*", "")
		print("✓ Number removed")
	else
		-- Add number
		line = "1. " .. line
		print("✓ Number added")
	end

	vim.fn.setline(line_num, line)
end

-- Toggle Bullet Points for (Visual Selection)
function ToggleBulletVisualSelection()
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	local lines = vim.fn.getline(start_line, end_line)

	-- Check if any line has bullets
	local has_bullets = false
	for i = 1, #lines do
		if lines[i]:match("^%s*[%-%*%+]%s") then
			has_bullets = true
			break
		end
	end

	if has_bullets then
		-- Remove bullets
		for i = 1, #lines do
			lines[i] = lines[i]:gsub("^(%s*)[%-%*%+]%s*", "%1")
		end
		print("✓ Bullets removed")
	else
		-- Add bullets
		for i = 1, #lines do
			-- Only add bullet if line isn't already a bullet or checkbox
			if not lines[i]:match("^%s*[%-%*%+]%s") and not lines[i]:match("^%s*%d+%.%s") then
				lines[i] = "- " .. lines[i]
			end
		end
		print("✓ Bullets added")
	end

	vim.fn.setline(start_line, lines)
end

-- Toggle Bullet Points for Current Line (Normal Mode)
function ToggleBulletCurrentLine()
	local line_num = vim.fn.line(".")
	local line = vim.fn.getline(line_num)

	if line:match("^%s*[%-%*%+]%s") then
		-- Remove bullet
		line = line:gsub("^(%s*)[%-%*%+]%s*", "%1")
		print("✓ Bullet removed")
	else
		-- Add bullet
		if not line:match("^%s*%d+%.%s") then
			line = "- " .. line
			print("✓ Bullet added")
		end
	end

	vim.fn.setline(line_num, line)
end

-- Setting commands
vim.api.nvim_create_user_command("ToggleNumberVisual", ToggleNumberVisualSelection, {})
vim.api.nvim_create_user_command("ToggleBulletVisual", ToggleBulletVisualSelection, {})

-- Keymaps for Bullet, Checkbox, Number list
-- visual mode keymaps (use commands to preserve selection)
vim.keymap.set({ "n", "v" }, "<leader>mn", ":<C-u>ToggleNumberVisual<CR>", {
	desc = "Toggle numbers on selected lines",
	buffer = true,
})

vim.keymap.set({ "n", "v" }, "<leader>m-", ":<C-u>ToggleBulletVisual<CR>", {
	desc = "Toggle bullets on selected lines",
	buffer = true,
})

-- ** Header Colors **
-- highlights for markdown files to render highlights properly
-- thx to Linkarzu for this

local color1_bg = "#ff757f"
local color2_bg = "#4fd6be"
local color3_bg = "#7dcfff"
local color4_bg = "#ff9e64"
local color5_bg = "#7aa2f7"
local color6_bg = "#c0caf5"
local color_fg = "#1F2335"

vim.cmd(
	string.format([[highlight @markup.heading.1.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg, color1_bg)
)
vim.cmd(
	string.format([[highlight @markup.heading.2.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg, color2_bg)
)
vim.cmd(
	string.format([[highlight @markup.heading.3.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg, color3_bg)
)
vim.cmd(
	string.format([[highlight @markup.heading.4.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg, color4_bg)
)
vim.cmd(
	string.format([[highlight @markup.heading.5.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg, color5_bg)
)
vim.cmd(
	string.format([[highlight @markup.heading.6.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg, color6_bg)
)

-- ** Reading a fiche: <leader>o = open it somewhere **
--
-- NOT under <leader>m. maplocalleader is Space, the same as mapleader, so
-- markdown-plus's <localleader>m* bindings land on <leader>m* -- 28 letters of
-- it, including ml (link), mp (paste link) and mr. Binding there silently
-- shadows them, because this ftplugin runs after the plugin's own, and the
-- plugin only declines to overwrite keys that already exist when *it* loads.
-- A separate prefix also survives markdown-plus claiming more letters later.
--
-- Second letter is the destination: r = in the buffer, b = browser, t = terminal.

vim.keymap.set("n", "<leader>or", "<cmd>RenderMarkdown buf_toggle<CR>", {
	desc = "Open: toggle in-buffer rendering",
	buffer = true,
})

vim.keymap.set("n", "<leader>ob", "<cmd>MarkdownPreview<CR>", {
	desc = "Open: browser preview (Mermaid, KaTeX, scroll sync)",
	buffer = true,
})

vim.keymap.set("n", "<leader>oB", "<cmd>MarkdownPreviewStop<CR>", {
	desc = "Open: stop the browser preview",
	buffer = true,
})

-- leaf reads the file from disk, not the buffer, so an unsaved edit would not
-- show up. Write first; -w then keeps the pane in sync on every later save.
vim.keymap.set("n", "<leader>ot", function()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("leaf: this buffer has no file on disk", vim.log.levels.WARN)
		return
	end
	if vim.fn.executable("leaf") == 0 then
		vim.notify("leaf: not installed (brew install leaf-markdown-viewer)", vim.log.levels.ERROR)
		return
	end
	if vim.bo.modified then
		vim.cmd.write()
	end
	vim.cmd("vsplit")
	vim.cmd("terminal leaf -w " .. vim.fn.shellescape(file))
	vim.cmd.startinsert()
end, { desc = "Open: read in leaf (terminal split)", buffer = true })
