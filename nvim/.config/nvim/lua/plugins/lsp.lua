vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/mason-org/mason-lspconfig.nvim", -- lspconfig bridge
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim", -- auto installer
})

require("mason").setup()
require("mason-lspconfig").setup()

-- Formatter/linter tools for Mason that are NOT LSP servers
local mason_tools = {
	"stylua",
	"shfmt",
	"markdownlint",
	"prettier",
	"biome",
	"jq",
	"tombi",
}

-- Each entry is passed directly to vim.lsp.config — keys are top-level lsp config fields
local lsp_servers = {
	-- Lua
	lua_ls = {
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				workspace = { library = vim.api.nvim_get_runtime_file("lua", true) },
				telemetry = { enable = false },
			},
		},
	},
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
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					diagnosticMode = "workspace",
					useLibraryCodeForTypes = true,
					typeCheckingMode = "basic",
					reportMissingImports = true,
				},
			},
		},
	},
	-- TS/JS
	ts_ls = {},
	-- CSS
	tailwindcss = {},
	-- Markdown
	marksman = {},
	-- XML/YAML
	yamlls = {},
	-- JSON
	jsonls = {},
	-- bash
	bashls = {
		filetypes = { "sh", "zsh" },
	},
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
	ensure_installed = vim.list_extend(vim.tbl_keys(lsp_servers), mason_tools),
})
vim.keymap.set("n", "<leader>M", vim.cmd.Mason, { desc = "Mason" })

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<leader>f", function()
	require("conform").format()
end, { desc = "Format Local buffer (Conform)" })

vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Documentation" })

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("mini.completion").get_lsp_capabilities())

for server, config in pairs(lsp_servers) do
	vim.lsp.config(server, vim.tbl_extend("keep", { capabilities = capabilities }, config))
end

-- Add custom LSP commands
vim.api.nvim_create_user_command("LspInfo", function()
	vim.cmd("checkhealth lsp")
end, { desc = "Show LSP client information" })
