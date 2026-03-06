vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim" },
})
require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
	notify_on_missing_formatters = true,
	formatters_by_ft = {
		bash = { " shfmt" },
		lua = { "stylua" },
		json = { "jq" },
		jsonc = { "jq" },
		python = {
			"ruff_format", -- Primary formatter
			"ruff_organize_imports", -- Import sorting
		},
		javascript = { "biome" },
		javascriptreact = { "biome" },
		typescript = { "biome" },
		typescriptreact = { "biome" },
		markdown = { "markdownlint" },
	},
})
