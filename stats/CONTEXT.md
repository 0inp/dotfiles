# Stats Module Context

## Purpose
Configuration for [Stats](https://github.com/exelban/stats), a macOS system monitoring widget.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `Stats.plist`            | Stats widget layout and settings     | `~/.config/stats/Stats.plist`      |

## Dependencies
- **Stats**: Install via Homebrew (`brew install --cask stats`).

## Key Features
- **Widgets**: CPU, memory, disk, network, and battery monitoring.
- **Layout**: Custom widget positions and sizes.
- **Appearance**: Themes and colors.

## AI Notes
- Focus on `Stats.plist` for widget customization.
- Test changes by reloading Stats (`Cmd + R` in the menu bar).