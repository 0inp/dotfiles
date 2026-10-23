# Git Module Context

## Purpose
Configuration for Git, including global settings, aliases, and tool integrations.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.gitconfig`             | Global Git configuration             | `~/.gitconfig`                     |
| `.gitignore`             | Global Git ignore rules              | `~/.gitignore`                     |

## Dependencies
- **Git**: Install via Homebrew (`brew install git`).

## Key Features
- **Aliases**: Shortcuts for common Git commands (e.g., `git lg` for `git log --oneline --graph`).
- **Ignore Rules**: Global ignore patterns (e.g., `.DS_Store`, `*.log`).
- **Performance**: `core.fsmonitor` + `core.untrackedCache` are on, so `git
  status` uses a background daemon instead of walking the worktree.
- **`push.autoSetupRemote`**: `git push` sets upstream on new branches by
  itself; the old `upush` alias was removed as redundant.

## AI Notes
- Focus on `.gitconfig` for aliases and global settings.
- Lazygit lives in its own `lazygit/` module.
- Test changes with `git config --global --list`.