local set = vim.opt_local

-- A fiche is one paragraph per line, so it is read soft-wrapped. textwidth
-- stays for `gq` on the hard-wrapped docs, but `t` would re-wrap a fiche on
-- the first keystroke.
set.textwidth = 80
set.formatoptions:remove("t")
set.wrap = true
set.breakindent = true

-- A fiche is French prose carrying English technical vocabulary, so a word is
-- accepted when either dictionary knows it. fr.utf-8.spl is not shipped with
-- Neovim; scripts/install.sh fetches it.
set.spelllang = "fr,en"
set.spell = true
set.spelloptions = "camel"
set.spellfile = vim.fn.stdpath("config") .. "/spell/fr.utf-8.add"
set.linebreak = true
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

-- A paragraph is one line now, so a bare j or k would skip it whole. A count
-- still addresses real lines, which is what relative numbers point at.
vim.keymap.set({ "n", "v" }, "j", function()
	return vim.v.count == 0 and "gj" or "j"
end, { expr = true, buffer = true })

vim.keymap.set({ "n", "v" }, "k", function()
	return vim.v.count == 0 and "gk" or "k"
end, { expr = true, buffer = true })

-- Not <leader>m: maplocalleader is Space, so markdown-plus's <localleader>m*
-- bindings occupy that range and this ftplugin, loading later, would shadow
-- them. Second letter is the destination: r buffer, b browser, t terminal.

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

-- leaf reads from disk, so an unsaved buffer would render stale.
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
