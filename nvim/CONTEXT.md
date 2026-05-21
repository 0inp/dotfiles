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
- **LSP**: Language Server Protocol integration.

## AI Notes
- Focus on `init.lua` and `lua/` for core configuration.
- Use `nvim-pack-lock.json` to track plugin versions.
- Test changes by launching `nvim`.
