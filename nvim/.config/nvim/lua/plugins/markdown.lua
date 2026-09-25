-- Markdown: three separate ways to read the same file, on purpose.
--
--   in-buffer  render-markdown.nvim   default, no moving parts
--   browser    markdown-preview.nvim  Mermaid + KaTeX, opt-in per buffer
--   terminal   leaf                   read-only pane, next to a Claude pane
--
-- markdown-plus.nvim is the *editing* layer (headings, lists, tables,
-- callouts, links). It has no rendering module at all, which is why
-- render-markdown.nvim is a complement and not a duplicate.

vim.pack.add({
	"https://github.com/yousefhadder/markdown-plus.nvim",
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
})
require("markdown-plus").setup()
require("render-markdown").setup({
	-- Defaults otherwise: they are tuned to look right, so only the two
	-- renderers that checkhealth flags as unbacked are switched off.
	-- Neither is worth a treesitter parser here: the fiches carry no YAML
	-- frontmatter and no LaTeX (which would also want utftex/latex2text).
	latex = { enabled = false },
	yaml = { enabled = false },
})

-- Neovim compiles spell/<lang>.add into .add.spl only when you press zg or zw.
-- A dictionary that arrived by `git pull` on another machine would therefore
-- never take effect -- silently, the words simply stay underlined. Rebuild it
-- whenever the source is newer than the compiled form.
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
	-- "multi", NOT "takeover" -- see the note in nvim/CONTEXT.md.
	--
	-- In takeover mode a single Neovim owns the fixed port 8421 and the single
	-- shared browser tab. A *second* Neovim takes the secondary branch of
	-- markdown_preview/init.lua, writes its content, adopts the primary's
	-- token, and returns -- before reaching either open_browser call site.
	-- So with two files open in two instances (the normal case here),
	-- :MarkdownPreview in the second one silently does nothing: no tab, no
	-- error, no message.
	--
	-- "multi" gives every instance its own OS-assigned port and its own tab.
	instance_mode = "multi",
	port = 0, -- 0 = OS-assigned (multi); would mean the fixed 8421 in takeover
	open_browser = true,
	default_theme = "dark",
	debounce_ms = 300,
})
