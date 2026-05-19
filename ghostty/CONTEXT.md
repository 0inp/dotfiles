# Ghostty Module Context

## Purpose
Configuration for [Ghostty](https://github.com/ghostty-org/ghostty), a GPU-accelerated terminal emulator for macOS.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config`                 | Terminal keybindings, appearance, and behavior | `~/.config/ghostty/config` |

## Dependencies
- **Ghostty**: Install via Homebrew (`brew install --cask ghostty`).

## Key Features
- **Keybindings**: Custom shortcuts for tabs, panes, and scrolling.
- **Appearance**: Themes, fonts, and transparency settings.
- **Behavior**: Shell integration, copy/paste, and mouse support.

## AI Notes
- Focus on `config` for keybindings and appearance.
- Test changes by reloading Ghostty (`Cmd + R`).