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
	"goimports",
	"golangci-lint", -- golangci_lint_ls is only a bridge; this does the linting
}

-- Each entry is passed directly to vim.lsp.config — keys are top-level lsp config fields
local lsp_servers = {
	-- Lua
	lua_ls = {
		settings = {
			Lua = {
				diagnostics = { globals = { "vim" } },
				-- The `vim.*` API. The runtime-file list it replaces was read before half
				-- the plugins loaded, so it was partial and still indexed every plugin.
				workspace = { library = { vim.env.VIMRUNTIME } },
				telemetry = { enable = false },
			},
		},
	},
	-- Python
	-- The native `ruff server` takes structured settings. `args` belonged to the
	-- retired ruff-lsp and was silently ignored, so ruff linted with its defaults.
	-- A project's own pyproject.toml / ruff.toml still wins (configurationPreference).
	ruff = {
		init_options = {
			settings = {
				lineLength = 88,
				lint = {
					select = { "ALL" },
					ignore = { "D203", "D212", "E501" },
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
	-- TS/JS — TypeScript 7's native (Go) language server, `tsc --lsp --stdio`.
	-- Not a Mason package: Mason has no `typescript` registry entry, so the
	-- binary comes from mise (`"npm:typescript" = "7"`) instead. See
	-- `non_mason_servers` below.
	tsc = {},
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
	-- nvim-lspconfig's defaults: they root on go.mod / .golangci.yml before .git
	-- and neutralise a project's own output settings.
	golangci_lint_ls = {},
}

-- Servers whose binary does NOT come from Mason. They must be excluded from
-- `ensure_installed` (mason-tool-installer errors on unknown registry names)
-- and enabled by hand, because mason-lspconfig's `automatic_enable` only fires
-- for servers Mason itself installed.
local non_mason_servers = {
	tsc = true, -- from mise: "npm:typescript" = "7"
}

local mason_servers = vim.tbl_filter(function(name)
	return not non_mason_servers[name]
end, vim.tbl_keys(lsp_servers))

require("mason-tool-installer").setup({
	ensure_installed = vim.list_extend(mason_servers, mason_tools),
})
vim.keymap.set("n", "<leader>M", vim.cmd.Mason, { desc = "Mason" })

-- Buffer-local, so buffers without a client keep Vim's own `gd`. `K` needs no
-- mapping: Neovim maps it to hover on attach unless something else claimed it,
-- and the old global one broke `K` in help buffers.
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
	end,
})

-- Neovim 0.12 maps `grr`/`gri` itself (runtime/lua/vim/_core/defaults.lua), and
-- both dump multiple results into the quickfix list. These globals shadow those
-- defaults and route the same requests through MiniPick instead, via the
-- `on_list` hook that `vim.lsp.buf.*` already accepts. `grt` (type definition),
-- `grn`, `gra` and `gO` keep the stock behaviour.
vim.keymap.set("n", "grr", function()
	require("mini.extra").pickers.lsp({ scope = "references" })
end, { desc = "References (MiniPick)" })

vim.keymap.set("n", "gri", function()
	require("mini.extra").pickers.lsp({ scope = "implementation" })
end, { desc = "Implementation (MiniPick)" })

vim.keymap.set("n", "<leader>f", function()
	require("conform").format()
end, { desc = "Format Local buffer (Conform)" })

-- Neovim merges this over its own default capabilities for every server.
vim.lsp.config("*", { capabilities = require("mini.completion").get_lsp_capabilities() })

for server, config in pairs(lsp_servers) do
	vim.lsp.config(server, config)
end

-- Mason-installed servers are enabled by mason-lspconfig; these are not.
vim.lsp.enable(vim.tbl_keys(non_mason_servers))
