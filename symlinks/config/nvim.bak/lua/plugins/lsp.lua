-- LSP Support

-- LSP Configuration
local base_pathes = {
  repos = vim.fn.expand '~/dev',
  config_home = vim.fn.expand '$XDG_CONFIG_HOME',
}

local config = {
  pathes = {
    repos = base_pathes.repos,
    config = {
      nvim = base_pathes.config_home .. '/nvim',
    },
  },
  ensure_installed = {
    -- :h mason-lspconfig-server-map
    servers = {
      'astro',
      'bashls',
      'cssls',
      'html',
      'jsonls',
      'lua_ls',
      'marksman',
      'pyright',
      'taplo',
      'tsserver',
      'yamlls',
    },
    -- :h mason-tool-installer
    tools = {
      'black',
      'debugpy',
      'flake8',
      'isort',
      'js-debug-adapter',
      'mypy',
      'pylint',
      'prettierd',
      'shellcheck',
      'shfmt',
      'stylua',
      'yamllint',
    },
  },
}

return {
  {
    -- https://github.com/williamboman/mason.nvim
    'williamboman/mason.nvim',
    opts = {},
    config = function(_, opts)
      require('mason').setup(opts)
    end,
  },
  {
    -- https://github.com/neovim/nvim-lspconfig
    'williamboman/mason-lspconfig.nvim',
    dependencies = {
      'williamboman/mason.nvim',
      'neovim/nvim-lspconfig',
      -- Additional lua configuration, makes nvim stuff amazing!
      -- https://github.com/folke/neodev.nvim
      'folke/neodev.nvim',
      -- Useful status updates for LSP
      -- https://github.com/j-hui/fidget.nvim
      { 'j-hui/fidget.nvim', opts = {} },

      -- Autoformatting
      'stevearc/conform.nvim',

      -- Schema information
      'b0o/SchemaStore.nvim',
    },
    config = function()
      require('neodev').setup {
        -- library = {
        --   plugins = { "nvim-dap-ui" },
        --   types = true,
        -- },
      }

      local capabilities = nil
      if pcall(require, 'cmp_nvim_lsp') then
        capabilities = require('cmp_nvim_lsp').default_capabilities()
      end

      local lspconfig = require 'lspconfig'

      local servers = {
        bashls = true,
        lua_ls = true,
        pyright = true,
        prettier = true,
        html = true,
        cssls = true,
        -- black = true,
        -- isort = true,

        -- Probably want to disable formatting for this lang server
        tsserver = true,

        jsonls = {
          settings = {
            json = {
              schemas = require('schemastore').json.schemas(),
              validate = { enable = true },
            },
          },
        },

        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,
                url = '',
              },
              schemas = require('schemastore').yaml.schemas(),
            },
          },
        },
      }

      local servers_to_install = vim.tbl_filter(function(key)
        local t = servers[key]
        if type(t) == 'table' then
          return not t.manual_install
        else
          return t
        end
      end, vim.tbl_keys(servers))

      require('mason').setup()
      local ensure_installed = {
        'stylua',
      }

      vim.list_extend(ensure_installed, servers_to_install)
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      for name, config in pairs(servers) do
        if config == true then
          config = {}
        end
        config = vim.tbl_deep_extend('force', {}, {
          capabilities = capabilities,
        }, config)

        lspconfig[name].setup(config)
      end

      local disable_semantic_tokens = {
        lua = true,
      }

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local bufnr = args.buf
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id), 'must have valid client')

          vim.opt_local.omnifunc = 'v:lua.vim.lsp.omnifunc'
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = 0 })
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = 0 })
          vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = 0 })
          vim.keymap.set('n', 'gT', vim.lsp.buf.type_definition, { buffer = 0 })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = 0 })

          vim.keymap.set('n', '<space>cr', vim.lsp.buf.rename, { buffer = 0 })
          vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, { buffer = 0 })

          local filetype = vim.bo[bufnr].filetype
          if disable_semantic_tokens[filetype] then
            client.server_capabilities.semanticTokensProvider = nil
          end
        end,
      })

      -- Autoformatting Setup
      require('conform').setup {
        formatters_by_ft = {
          lua = { 'stylua' },
          css = { 'prettier', 'cssls' },
          html = { 'prettier', 'html' },
          -- python = { 'black', 'isort' },
        },
      }

      vim.api.nvim_create_autocmd('BufWritePre', {
        callback = function(args)
          require('conform').format {
            bufnr = args.buf,
            lsp_fallback = true,
            quiet = true,
          }
        end,
      })
    end,
  },
  {
    -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = 'williamboman/mason.nvim',
    -- https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim/issues/39
    lazy = false,
    opts = {
      ensure_installed = config.ensure_installed.tools,
    },
  },
  {
    -- https://github.com/stevearc/conform.nvim
    'stevearc/conform.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        -- Customize or remove this keymap to your liking
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = '',
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        css = { { 'prettierd', 'prettier' } },
        scss = { { 'prettierd', 'prettier' } },
        graphql = { { 'prettierd', 'prettier' } },
        html = { { 'prettierd', 'prettier' } },
        javascript = { { 'prettierd', 'prettier' } },
        javascriptreact = { { 'prettierd', 'prettier' } },
        json = { { 'prettierd', 'prettier' } },
        lua = { 'stylua' },
        markdown = { { 'prettierd', 'prettier' } },
        python = { 'black', 'isort' },
        typescript = { { 'prettierd', 'prettier' } },
        typescriptreact = { { 'prettierd', 'prettier' } },
        yaml = { 'prettierd', 'prettier' },
        toml = { 'taplo' },
        sh = { 'shfmt' },
      },
      format_on_save = {
        -- These options will be passed to conform.format()
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
    -- config = function()
    --   local slow_format_filetypes = {}
    --   require('conform').setup {
    --     format_on_save = function(bufnr)
    --       if slow_format_filetypes[vim.bo[bufnr].filetype] then
    --         return
    --       end
    --       local function on_format(err)
    --         if err and err:match 'timeout$' then
    --           slow_format_filetypes[vim.bo[bufnr].filetype] = true
    --         end
    --       end
    --
    --       return { timeout_ms = 200, lsp_fallback = true }, on_format
    --     end,
    --
    --     format_after_save = function(bufnr)
    --       if not slow_format_filetypes[vim.bo[bufnr].filetype] then
    --         return
    --       end
    --       return { lsp_fallback = true }
    --     end,
    --   }
    -- end,
  },
  {
    -- https://github.com/brenoprata10/nvim-highlight-colors
    'brenoprata10/nvim-highlight-colors',
    config = function()
      require('nvim-highlight-colors').setup {}
    end,
  },
}
