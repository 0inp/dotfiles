# Aerospace Module Context

## Purpose
Configuration for [Aerospace](https://github.com/nikitabobko/AeroSpace), a tiling window manager for macOS.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `aerospace.toml`         | Window manager layout and keybindings| `~/.config/aerospace/aerospace.toml` |

## Dependencies
- **Aerospace**: Install via Homebrew (`brew install --cask nikitabobko/aerospace/aerospace`).
- **macOS**: Requires macOS 13.0+.

## Key Features
- **Workspaces**: Dynamic workspaces for app grouping.
- **Keybindings**: Vim-style navigation and window management.
- **Layouts**: Tiling and floating window support.

## AI Notes
- Focus on `aerospace.toml` for layout and keybinding changes.
- Test changes by reloading Aerospace (`aerospace reload-config`).