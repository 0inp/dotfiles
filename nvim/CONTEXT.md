# Neovim Module Context

## Purpose
Configuration for [Neovim](https://neovim.io/), a modern Vim-based text editor.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `init.lua`               | Entry point for Neovim configuration | `~/.config/nvim/init.lua`          |
| `nvim-pack-lock.json`    | Lockfile for plugin versions         | `~/.config/nvim/nvim-pack-lock.json` |
| `lua/`                   | Lua modules for plugins and settings | `~/.config/nvim/lua/`               |
| `after/`                 | Post-load configurations             | `~/.config/nvim/after/`             |

## Dependencies
- **Neovim**: Install via Homebrew (`brew install neovim`).
- **Plugins**: Managed via `lazy.nvim` (defined in `lua/plugins.lua`).

## Key Features
- **Lua Config**: Modern Lua-based configuration.
- **Plugins**: Package management with `lazy.nvim`.
- **Keybindings**: Custom shortcuts for editing and navigation.
- **LSP**: Language Server Protocol integration. Servers are declared in
  `lua/plugins/lsp.lua`; most are installed by Mason via mason-tool-installer.

## TypeScript: `tsc`, not `ts_ls`
TS/JS uses **`tsc`** — TypeScript 7's native (Go) language server, run as
`tsc --lsp --stdio`. It replaced `ts_ls` (the old Node `tsserver`); upstream
lspconfig also deprecated the interim `tsgo` beta in favour of `tsc`.

Its binary does **not** come from Mason (there is no `typescript` package in the
registry) — it comes from mise, via `"npm:typescript" = "7"`. Servers in that
situation must be listed in `non_mason_servers` in `lsp.lua`, which does two
things: keeps the name out of `ensure_installed`, and enables the server by hand
with `vim.lsp.enable`. That second part matters — **mason-lspconfig's
`automatic_enable` only fires for servers Mason itself installed**, so a
non-Mason server that is merely configured will never attach.

Corollary: removing a server from `lsp_servers` does not disable it if Mason
still has the package installed. `ts_ls` kept attaching until
`:MasonUninstall typescript-language-server` was run.

## AI Notes
- Focus on `init.lua` and `lua/` for core configuration.
- Use `nvim-pack-lock.json` to track plugin versions.
- Test changes by launching `nvim`.
