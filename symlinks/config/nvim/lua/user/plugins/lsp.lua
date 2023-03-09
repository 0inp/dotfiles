local lsp_servers = {
  "bashls",
  "dockerls",
  "html",
  "jsonls",
  "lua_ls",
  "pyright",
}

-- LSP custom function when client attaches to buffer.
-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
-- local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local on_attach = function(client, bufnr)
  local format_timeout_ms = 2000
  local lsp_format = require("lsp-format")
  -- Auto-format on save
  lsp_format.on_attach(client)
  -- if client.supports_method("textDocument/formatting") then
  -- 	vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
  -- 	vim.api.nvim_create_autocmd("BufWritePre", {
  -- 		group = augroup,
  -- 		buffer = bufnr,
  -- 		callback = function()
  -- 			-- on 0.8, you should use vim.lsp.buf.format({ bufnr = bufnr }) instead
  -- 			vim.lsp.buf.formatting_sync()
  -- 		end,
  -- 	})
  -- end

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local wk = require("which-key")

  -- Without prefix:
  wk.register({
        ["["] = {
      d = {
        vim.lsp.diagnostic.goto_prev,
        "Previous diagnostic",
        buffer = bufnr,
      },
    },
        ["]"] = {
      d = {
        vim.lsp.diagnostic.goto_next,
        "Next diagnostic",
        buffer = bufnr,
      },
    },
    g = {
      d = { vim.lsp.buf.definition, "Go to definition", buffer = bufnr },
      i = { vim.lsp.buf.implementation, "Go to implementation", buffer = bufnr },
      r = {
        ":Trouble lsp_references<CR>",
        "List references",
        buffer = bufnr,
      },
      t = { vim.lsp.buf.type_definition, "Go to type definition", buffer = bufnr },
    },
    K = { vim.lsp.buf.hover, "Hover doc", buffer = bufnr },
  })

  -- With leader prefix:
  wk.register({
    b = {
      f = {
        function()
          vim.lsp.buf.format({ async = true, timeout_ms = format_timeout_ms })
        end,
        "Format buffer",
        buffer = bufnr,
      },
    },
    c = {
      a = {
        function()
          vim.lsp.buf.code_action({ apply = true })
        end,
        "Code actions",
        buffer = bufnr,
      },
      e = {
        vim.lsp.diagnostic.open_float,
        "Line diagnostics",
        buffer = bufnr,
      },
      k = { vim.lsp.buf.signature_help, "Signature help", buffer = bufnr },
      r = { vim.lsp.buf.rename, "Rename", buffer = bufnr },
    },
        ["<tab>"] = {
      name = "Workspace",
      a = {
        vim.lsp.buf.add_workspace_folder,
        "Add workspace folder",
        buffer = bufnr,
      },
      l = {
        function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end,
        "List workspace folders",
        buffer = bufnr,
      },
      r = {
        vim.lsp.buf.remove_workspace_folder,
        "Remove workspace folder",
        buffer = bufnr,
      },
    },
  }, { prefix = "<leader>" })

  -- Visual mode with leader prefix:
  wk.register({
    c = {
      a = {
        function()
          vim.lsp.buf.code_action({ apply = true })
        end,
        "Code actions",
        buffer = bufnr,
      },
    },
  }, { prefix = "<leader>", mode = "v" })
end

return {
  {
    "neovim/nvim-lspconfig", -- Configurations for Nvim LSP
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "b0o/schemastore.nvim",  -- Schemas for JSON files
      "hrsh7th/cmp-nvim-lsp",  -- See cmp.lua for more info
      {
        "williamboman/mason.nvim", -- Manage language servers, linters, etc.
        -- IMPORTANT: Mason must be set up before lspconfig and null-ls
        priority = 500,
        config = function()
          -- Mason to manage external tools like language servers
          require("mason").setup()
          require("mason-lspconfig").setup({
            ensure_installed = lsp_servers,
            automatic_installation = true,
          })
        end,
      },
      {
        "williamboman/mason-lspconfig.nvim", -- Integration mason/lsp
      },
      {
        "jayp0521/mason-null-ls.nvim", -- Integration mason/null-ls
        config = function()
          -- Mason Null-ls handles the installation of the configured sources
          require("mason-null-ls").setup({
            ensure_installed = nil, -- nil, as taken from null_ls setup
            automatic_installation = true,
            automatic_setup = true,
          })
        end,
      },
      {
        "lukas-reineke/lsp-format.nvim", -- Easier management of auto-saving from LSP sources
        opts = {},
      },
    },
    config = function()
      local lsp_flags = {
        -- This is the default in Nvim 0.7+
        debounce_text_changes = 150,
      }

      -- Add additional capabilities supported by nvim-cmp
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lspconfig = require("lspconfig")

      -- Enable some language servers with the additional completion capabilities offered by nvim-cmp
      for _, lsp in ipairs(lsp_servers) do
        lspconfig[lsp].setup({
          on_attach = on_attach,
          flags = lsp_flags,
          capabilities = capabilities,
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
            Lua = {
              diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { "vim" },
              },
            },
          },
        })
      end
    end,
  },
  {
    "jose-elias-alvarez/null-ls.nvim", -- NeoVim as LSP server
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local null_ls = require("null-ls")
      local null_ls_sources = {
        null_ls.builtins.diagnostics.flake8, -- Python
        null_ls.builtins.diagnostics.gitlint, -- Git coventional commit
        null_ls.builtins.diagnostics.hadolint, -- Docker best practices
        null_ls.builtins.diagnostics.mypy,   -- Python
        null_ls.builtins.diagnostics.shellcheck, -- Shell
        null_ls.builtins.formatting.black,   -- Python
        null_ls.builtins.formatting.isort,   -- Python
        null_ls.builtins.formatting.jq,      -- JSON
        null_ls.builtins.formatting.shfmt,   -- Shell
        null_ls.builtins.formatting.stylua,  -- Lua
        null_ls.builtins.formatting.yamlfmt, -- YAML
      }
      --
      -- NeoVim LSP server capabilities
      null_ls.setup({
        sources = null_ls_sources,
        on_attach = on_attach,
      })
    end,
  },
}