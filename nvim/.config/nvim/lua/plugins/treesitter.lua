vim.pack.add({
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
})

local treesitter = require("nvim-treesitter")

local ensure_installed = {
	"bash",
	"css",
	"dockerfile",
	"go",
	"html",
	"http",
	"javascript",
	"json",
	"lua",
	"markdown",
	-- Required by render-markdown.nvim. It is already on disk today only
	-- because it ships as a silent companion of the markdown parser -- not
	-- because anything asked for it. Make that explicit.
	"markdown_inline",
	"python",
	"query",
	"rust",
	"toml",
	"tsx",
	"typescript",
	"vim",
	"vimdoc",
}

treesitter.install(ensure_installed)

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function(args)
		local buf = args.buf
		local ft = vim.bo[buf].filetype

		local lang = vim.treesitter.language.get_lang(ft)
		if not lang then
			return
		end

		local ok_add = pcall(vim.treesitter.language.add, lang)
		if not ok_add then
			return
		end

		pcall(vim.treesitter.start, buf, lang)
	end,
})
