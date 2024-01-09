# Dotfiles

## Add a plugin
Just add a file in `lua/plugins/` with the following format:
```
local M = {
    {
        "github_path/plugin_name",
        options_installations = opts
        config = function()
            Put here options for the plugin
        end
    },
}
return M
```

## Add a language
### Treesitter
This should install automatically when encountering a new language

### LSP
Just check what are the better tools for linting or provide diagnostics, formatting and for debugging.
For example, in Python(3), the tool `ruff` does really well all the linting and formatting part (and can replace tools such as isort, black, flake8, etc.) but you'll need debugpy for the debugging part.
In Javascript, it is common rule to find eslint for the linting/diagnostics part and prettier for the formatting part.

Some of the tools have been converted into lsp. just check this [list](https://github.com/williamboman/mason-lspconfig.nvim?tab=readme-ov-file#available-lsp-servers).
Others need the none-ls tools to communicate with the proper command line tool.

#### Linting
If it exists a LSP server for your linting, you just need to add the name of that LSP in the `ensure_installed` table of the `mason-lspconfig` configuration in the `lua/plugins/lsp.lua` file.

If you need an external tool (ex: the static type checker `mypy`), you need to add it in the `mason-null-ls` configuration, in the `ensure_installed` table.
Moreover, you'll need to add the proper configuration in the `none-ls` plugin. Example with `mypy`
```
{
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")

        null_ls.setup({
            sources = {
                -- This line is what you need to add
                null_ls.builtins.diagnostics.mypy,
                --
            },
        })
        vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
    end,
}
```

#### Formatting
If you need an external tool (ex: the javascript formatting tool `prettier`), you need to add it in the `mason-null-ls` configuration, in the `ensure_installed` table.
Moreover, you'll need to add the proper configuration in the `none-ls` plugin. Example with `mypy`
```
{
    "nvimtools/none-ls.nvim",
    config = function()
        local null_ls = require("null-ls")

        null_ls.setup({
            sources = {
                -- This line is what you need to add
                null_ls.builtins.formatting.prettier,
                --
            },
        })
        vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
    end,
}
```
#### Debugging
