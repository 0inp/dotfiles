vim.pack.add({
	{ src = "https://github.com/stevearc/conform.nvim" },
})

-- Prettier when the project configures it, Biome otherwise. `require_cwd` on
-- prettier (below) makes it unavailable outside a project with a prettier
-- config, which conform's prettier recognises in all its forms, package.json
-- included; `stop_after_first` then falls through to biome.
local prettier_or_biome = { "prettier", "biome", stop_after_first = true }

require("conform").setup({
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	notify_on_missing_formatters = true,
	formatters_by_ft = {
		sh = { "shfmt" },
		css = { "prettier" },
		go = { "goimports", "gofmt", stop_after_first = true }, -- goimports also gofmts
		html = { "prettier" },
		json = { "jq", "biome", stop_after_first = true },
		jsonc = { "jq", "biome", stop_after_first = true },
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
	-- Match scripts/checks.sh and lefthook.yml. Without this, shfmt
	-- formats with its default tab indent on save while the pre-commit
	-- hook rewrites the same file to 2 spaces, and the two fight.
	formatters = {
		prettier = { require_cwd = true },
		shfmt = {
			prepend_args = { "-i", "2", "-ci", "-bn" },
		},
	},
})
