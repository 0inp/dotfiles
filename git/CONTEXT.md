# Git Module Context

## Purpose
Configuration for Git, including global settings, aliases, and tool integrations.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.gitconfig`             | Global Git configuration             | `~/.gitconfig`                     |
| `.gitignore`             | Global Git ignore rules              | `~/.gitignore`                     |
| `lazygit.yaml`           | Lazygit theme/GUI settings           | `~/.config/lazygit.yaml`           |

## Dependencies
- **Git**: Install via Homebrew (`brew install git`).
- **Lazygit**: Install via Homebrew (`brew install lazygit`).

## Key Features
- **Aliases**: Shortcuts for common Git commands (e.g., `git lg` for `git log --oneline --graph`).
- **Ignore Rules**: Global ignore patterns (e.g., `.DS_Store`, `*.log`).
- **Lazygit**: TUI theme and GUI settings. `.zshenv` points `LG_CONFIG_FILE`
  at this file. NOTE: a separate `lazygit/` module owns
  `~/.config/lazygit/config.yml` for `customCommands` — see the overlap note in
  `CONTEXT_MAP.md`.
- **Performance**: `core.fsmonitor` + `core.untrackedCache` are on, so `git
  status` uses a background daemon instead of walking the worktree.
- **`push.autoSetupRemote`**: `git push` sets upstream on new branches by
  itself; the old `upush` alias was removed as redundant.

## AI Notes
- Focus on `.gitconfig` for aliases and global settings.
- Update `lazygit.yaml` for TUI customizations.
- Test changes with `git config --global --list`.