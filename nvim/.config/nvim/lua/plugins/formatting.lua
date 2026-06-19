vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim" },
})

local function prettier_or_biome(bufnr)
	-- Check for Prettier configs manually (simplified)
	local prettier_configs = {
		".prettierrc",
		".prettierrc.json",
		".prettierrc.js",
		"prettier.config.js",
	}
	for _, config in ipairs(prettier_configs) do
		if vim.fn.filereadable(vim.fn.findfile(config, ".;")) == 1 then
			return { "prettier", timeout_ms = 10000 }
		end
	end
	-- Fallback to Biome
	return { "biome" }
end

require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
	notify_on_missing_formatters = true,
	formatters_by_ft = {
		bash = { " shfmt" },
		css = { "prettier" },
		go = { "gofmt", "goimports" },
		html = { "prettier" },
		json = { "jq", "biome" },
		jsonc = { "jq", "biome" },
		lua = { "stylua" },
		markdown = { "markdownlint" },
		python = {
			"ruff_format", -- Primary formatter
			"ruff_organize_imports", -- Import sorting
		},
		javascript = prettier_or_biome,
		javascriptreact = prettier_or_biome,
		typescript = prettier_or_biome,
		typescriptreact = prettier_or_biome,
	},
})

require("conform").setup({
	formatters_by_ft = {},
})
