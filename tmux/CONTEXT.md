# Tmux Module Context

## Purpose
Configuration for [Tmux](https://github.com/tmux/tmux), a terminal multiplexer.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `tmux.conf`              | Tmux keybindings and behavior        | `~/.config/tmux/tmux.conf`         |
| `.tmux/`                 | Tmux plugins and scripts             | `~/.config/tmux/.tmux/`            |
| `scripts/`               | Custom Tmux scripts                  | `~/.config/tmux/scripts/`          |

## Dependencies
- **Tmux**: Install via Homebrew (`brew install tmux`).
- **Plugins**: Managed via [TPM](https://github.com/tmux-plugins/tpm) (Tmux Plugin Manager).

## Key Features
- **Keybindings**: Custom shortcuts for sessions, windows, and panes.
- **Plugins**: Extensions for themes, copy-mode, and integration.
- **Scripts**: Automation for common workflows.

## AI Notes
- Focus on `tmux.conf` for keybindings and behavior.
- Use `.tmux/` for plugin management.
- Test changes by reloading Tmux (`Ctrl + b` then `:source-file ~/.config/tmux/tmux.conf`).