# Scripts Module Context

## Purpose
Custom scripts for dotfiles management and system automation.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `install.sh`             | Dotfiles installation script         | `~/.local/bin/install-dotfiles`    |
| `update.sh`              | System update script                 | `~/.local/bin/update-system`       |

## Dependencies
- **Shell**: Requires `zsh` or `bash`.
- **Stow**: Install via Homebrew (`brew install stow`).

## Key Features
- **Installation**: Automates dotfiles symlinking and dependency setup.
- **Updates**: Orchestrates system updates (Homebrew, macOS, etc.).

## AI Notes
- Focus on `install.sh` for dotfiles setup.
- Use `update.sh` for system maintenance.
- Test changes by running scripts locally.