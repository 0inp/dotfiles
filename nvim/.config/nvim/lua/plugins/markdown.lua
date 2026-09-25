vim.pack.add({
	"https://github.com/yousefhadder/markdown-plus.nvim",
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
})
require("markdown-plus").setup()
require("render-markdown").setup({
	-- No parser installed for either, and latex would also want utftex.
	latex = { enabled = false },
	yaml = { enabled = false },
})

-- Neovim compiles spell/<lang>.add only on zg or zw, so a dictionary arriving
-- over git would stay inert.
local spell_add = vim.fn.stdpath("config") .. "/spell/fr.utf-8.add"
local add_stat = vim.uv.fs_stat(spell_add)
if add_stat then
	local spl_stat = vim.uv.fs_stat(spell_add .. ".spl")
	if not spl_stat or add_stat.mtime.sec > spl_stat.mtime.sec then
		vim.cmd("silent! mkspell! " .. vim.fn.fnameescape(spell_add))
	end
end

vim.pack.add({
	"https://github.com/selimacerbas/live-server.nvim",
	"https://github.com/selimacerbas/markdown-preview.nvim",
})
require("markdown_preview").setup({
	-- "takeover" shares one fixed port and one browser tab across instances: a
	-- second Neovim registers with the first and opens nothing at all.
	instance_mode = "multi",
	port = 0,
	open_browser = true,
	default_theme = "dark",
	debounce_ms = 300,
})
