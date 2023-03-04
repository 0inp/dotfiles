-------------------------------------------------
-- name : nvim-treesitter
-- url  : https://github.com/nvim-treesitter/nvim-treesitter
-------------------------------------------------
local M = {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "bash",
        "dockerfile",
        "json",
        "lua",
        "python",
        "yaml",
        "markdown",
        "markdown_inline",
        "html",
        "php",
        "sql",
        "vim",
      }, -- one of "all" or a list of languages
      highlight = {
        enable = true, -- false will disable the whole extension
        additional_vim_regex_highlighting = true,
      },
      autopairs = {
        enable = true,
      },
      indent = { enable = true },
    })
  end
}

return M
