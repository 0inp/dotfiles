# Herdr Module Context

## Purpose
Configuration for [Herdr](https://herdr.dev), an agent-aware terminal multiplexer.
Replaces tmux for AI agent workflows — sidebar shows blocked/working/done state per agent across all workspaces.

## Key Files
| File | Description | Symlink Target |
|------|-------------|----------------|
| `config.toml` | Keybindings, theme, UI, agent sound/toast settings | `~/.config/herdr/config.toml` |

## Dependencies
- **Herdr**: `brew install herdr`
- **Claude Code integration**: `herdr integration install claude` (run once after install)

## Key Features
- **Workspaces** map 1:1 to tmux sessions (one per project/git repo)
- **Sidebar** shows agent state at a glance; `prefix+b` toggles it
- **Keybindings** mirror tmux as closely as possible (same `ctrl+b` prefix)
- **Kanagawa theme** to match the rest of the setup
- **Sound + toasts** fire when an agent finishes or needs input

## Notable Keybinding Differences from Tmux
| Action | Tmux | Herdr |
|--------|------|-------|
| Split side-by-side | `prefix+\|` | `prefix+\|` (same) |
| Split top-bottom | `prefix+-` | `prefix+-` (same) |
| Rename workspace | `prefix+r` | `prefix+shift+w` |
| Resize panes | `prefix+,/.` etc. | `prefix+r` → `h/j/k/l` → `esc` |
| Session picker | `prefix+T` (sesh) | `prefix+w` (built-in) |

## Reload Config
```bash
herdr server reload-config
```
