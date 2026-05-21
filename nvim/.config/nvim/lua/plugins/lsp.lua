vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim", -- lspconfig bridge
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim", -- auto installer
})

require("mason").setup()
require("mason-lspconfig").setup()

local lsp_servers = {
	-- Lua
	lua_ls = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = { library = vim.api.nvim_get_runtime_file("lua", true) },
			telemetry = { enable = false },
		},
	},
	stylua = {},
	-- Python
	ruff = {
		init_options = {
			settings = {
				args = {
					"--select=ALL",
					"--ignore=D203,D212,E501",
					"--line-length=88",
				},
			},
		},
	},
	pyright = {
		python = {
			pythonPath = vim.fn.getcwd() .. "/.venv/bin/python",
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				useLibraryCodeForTypes = true,
				typeCheckingMode = "basic", -- or "strict"
				reportMissingImports = true,
			},
		},
	},
	-- TS/JS
	ts_ls = {},
	biome = {},
	-- CSS
	tailwindcss = {},
	-- HTML
	prettier = {},
	-- Markdown
	marksman = {},
	markdownlint = {},
	-- XML/YAML
	yamlls = {},
	-- JSON
	jsonls = {},
	jq = {},
	-- TOML
	tombi = {},
	-- bash
	bashls = {
		filetypes = { "sh", "zsh" },
	},
	shfmt = {},
	-- Go
	gopls = {
		settings = {
			gopls = {
				analyses = { unusedparams = true },
				staticcheck = true,
			},
		},
	},
	golangci_lint_ls = {
		cmd = { "golangci-lint-langserver" },
		root_markers = { ".git", "go.mod" },
		init_options = {
			command = {
				"golangci-lint",
				"run",
				"--output.json.path",
				"stdout",
				"--show-stats=false",
				"--issues-exit-code=1",
			},
		},
	},
}

require("mason-tool-installer").setup({
	ensure_installed = vim.tbl_keys(lsp_servers),
})
vim.keymap.set("n", "<leader>M", vim.cmd.Mason, { desc = "Mason" })

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, { desc = "Format Local buffer" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Documentation" })

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("mini.completion").get_lsp_capabilities())

for server, config in pairs(lsp_servers) do
	vim.lsp.config(server, { settings = config, capabilities = capabilities })
end

-- Add custom LSP commands
vim.api.nvim_create_user_command("LspInfo", function()
	vim.cmd("checkhealth lsp")
end, { desc = "Show LSP client information" })
