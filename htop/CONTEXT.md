# Htop Module Context

## Purpose
Configuration for `htop`, an interactive process viewer for Unix systems.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `htoprc`                 | Htop configuration and layout        | `~/.config/htop/htoprc`            |

## Dependencies
- **Htop**: Install via Homebrew (`brew install htop`).

## Key Features
- **Process Monitoring**: Real-time CPU, memory, and process tracking.
- **Layout**: Custom columns, colors, and sorting.
- **Keybindings**: Shortcuts for process management (e.g., `F6` to sort).

## AI Notes
- Focus on `htoprc` for layout and keybinding customizations.
- Test changes by launching `htop`.