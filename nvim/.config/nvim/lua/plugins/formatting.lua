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
    css = { "prettier" },
    go = { "gofmt", "goimports" },
    html = { "prettier" },
    javascript = { "biome" },
    javascriptreact = { "biome" },
    json = { "jq", "biome" },
    jsonc = { "jq", "biome" },
    lua = { "stylua" },
    markdown = { "markdownlint" },
    python = {
      "ruff_format",        -- Primary formatter
      "ruff_organize_imports", -- Import sorting
    },
    typescript = { "biome" },
    typescriptreact = { "biome" },
  },
})
