# Git Module Context

## Purpose
Configuration for Git, including global settings, aliases, and tool integrations.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.gitconfig`             | Global Git configuration             | `~/.gitconfig`                     |
| `.gitignore`             | Global Git ignore rules              | `~/.gitignore`                     |
| `lazygit.yaml`           | Lazygit TUI configuration            | `~/.config/lazygit/config.yml`     |

## Dependencies
- **Git**: Install via Homebrew (`brew install git`).
- **Lazygit**: Install via Homebrew (`brew install lazygit`).

## Key Features
- **Aliases**: Shortcuts for common Git commands (e.g., `git lg` for `git log --oneline --graph`).
- **Ignore Rules**: Global ignore patterns (e.g., `.DS_Store`, `*.log`).
- **Lazygit**: TUI for Git with custom keybindings and themes.

## AI Notes
- Focus on `.gitconfig` for aliases and global settings.
- Update `lazygit.yaml` for TUI customizations.
- Test changes with `git config --global --list`.