-- lsp servers we want to use and their configuration
-- see `:h lspconfig-all` for available servers and their settings
vim.pack.add({
	"https://github.com/neovim/nvim-lspconfig", -- default configs for lsps
	"https://github.com/mason-org/mason.nvim", -- package manager
	"https://github.com/mason-org/mason-lspconfig.nvim", -- lspconfig bridge
	"https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim", -- auto installer
}, { confirm = false })

require("mason").setup()
vim.keymap.set("n", "<leader>m", vim.cmd.Mason, { desc = "Mason" })
require("mason-lspconfig").setup()

local lsp_servers = {
	-- Lua
	lua_ls = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = { library = vim.api.nvim_get_runtime_file("lua", true) },
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
		settings = {
			python = {
				analysis = {
					autoSearchPaths = true,
					diagnosticMode = "openFilesOnly",
					useLibraryCodeForTypes = true,
					typeCheckingMode = "basic", -- or "strict"
				},
			},
		},
	},
	-- TS/JS
	ts_ls = {},
	biome = {},
	-- CSS
	tailwindcss = {},
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
	bashls = {},
	shfmt = {},
}

require("mason-tool-installer").setup({
	ensure_installed = vim.tbl_keys(lsp_servers),
})

-- configure each lsp server on the table
-- to check what clients are attached to the current buffer, use
-- `:checkhealth vim.lsp`. to view default lsp keybindings, use `:h lsp-defaults`.
local on_attach_keymaps = function(client, bufnr)
	vim.keymap.set("n", "<leader>co", function()
		vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } }, apply = true })
	end, { noremap = true, silent = true, desc = "[C]ode [O]rganize Imports", buffer = bufnr })
	vim.keymap.set("n", "<leader>ca", function()
		vim.lsp.buf.code_action({
			filter = function(action)
				return not action.disabled
			end,
		})
	end, { noremap = true, silent = true, desc = "[C]ode [A]ctions" })
	vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { noremap = true, silent = true, desc = "[C]ode [R]ename" })
	vim.keymap.set("n", "<leader>cf", vim.lsp.buf.format, { noremap = true, silent = true, desc = "[C]ode [F]ormat" })

	vim.keymap.set("n", "gd", vim.lsp.buf.definition, { noremap = true, silent = true, desc = "[G]o to [D]efinition" })
	vim.keymap.set("n", "K", vim.lsp.buf.hover, { noremap = true, silent = true, desc = "Documentation" })
	vim.keymap.set("n", "[d", function()
		vim.diagnostic.jump({ count = 1, float = true })
	end, { noremap = true, silent = true, desc = "Go to Next Diagnostic" })
	vim.keymap.set("n", "]d", function()
		vim.diagnostic.jump({ count = -1, float = true })
	end, { noremap = true, silent = true, desc = "Go to Previous Diagnostic" })
end

-- Add custom LSP commands
vim.api.nvim_create_user_command("LspInfo", function()
	vim.cmd("checkhealth lsp")
end, { desc = "Show LSP client information" })

-- Configure all LSP servers
for server, config in pairs(lsp_servers) do
	vim.lsp.config(server, { settings = config, on_attach = on_attach_keymaps })
end
--:
