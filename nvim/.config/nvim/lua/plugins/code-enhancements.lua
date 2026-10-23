-- mini.hipatterns replaces todo-comments (whose search commands needed plenary,
-- never installed) and nvim-colorizer. Tailwind colours come from the LSP:
-- textDocument/documentColor is built into Neovim 0.12.
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})

-- What :TodoQuickFix did: rg takes the pattern as a regex.
vim.keymap.set("n", "<leader>xt", function()
	require("mini.pick").builtin.grep({ pattern = [[\b(TODO|FIXME|HACK)\b]] })
end, { desc = "Search TODO/FIXME/HACK in project" })
