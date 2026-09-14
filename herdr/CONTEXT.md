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

## Mouse buttons cannot be bound — don't retry this
Investigated against 0.9.0 and settled. Three independent walls:

1. The `[keys]` parser has no mouse vocabulary — only keys, arrows, `f1`..`f20`
   and modifiers. `mouse4`, `button4`, `prefix+mouse4` are all rejected.
2. Herdr's internal mouse event type only knows `Left`, `Right`, `Middle`,
   `ScrollUp/Down/Left/Right`, `Moved` and `Drag`. A thumb button cannot be
   *represented*, so this is a data-model limit rather than a missing keyword.
3. Plugin actions fire on `keybinding` or `link_click` only; there is no hook on
   raw input events.

Ghostty has no mouse-button keybind trigger either, so a Herdr change alone
would not be enough.

Note the failure mode of wall 1: a bad `[keys]` entry is *quiet* —
`invalid keybinding: ...; disabling binding`, then Herdr runs on without that
binding. `herdr config check` is the only place it surfaces.

An OS-level remap (Karabiner-Elements, thumb button → `ctrl+b n`) does work and
was verified end to end, but it was removed again: capturing the mouse's
pointing collection to get there was more disruptive than the shortcut was
worth. `f13`..`f20` *are* accepted by `[keys]`, so if a future macOS tool can
turn a thumb button into an F-key without grabbing the device, that is the path
to reopen — `hidutil` accepts such a mapping but there is no evidence it
applies to the button usage page.
