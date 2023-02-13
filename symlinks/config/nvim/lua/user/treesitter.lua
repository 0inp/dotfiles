local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	return
end

configs.setup({
	ensure_installed = {
		"bash",
		"dockerfile",
		"json",
		"lua",
		"python",
		"yaml",
		"markdown",
		"markdown_inline",
		"html",
		"php",
		"sql",
		"vim",
	}, -- one of "all" or a list of languages
	highlight = {
		enable = true, -- false will disable the whole extension
		additional_vim_regex_highlighting = true,
	},
	autopairs = {
		enable = true,
	},
	indent = { enable = true },
})
