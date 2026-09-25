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

## Moving around

Prefix is `ctrl+b`. Full list in `config.toml`; these are the ones worth knowing.

| Action | Key |
|--------|-----|
| Toggle the agent sidebar | `prefix+b` |
| Next / previous agent | `prefix+]` / `prefix+[` |
| Jump straight to agent N | `prefix+ctrl+N` |
| Next / previous workspace | `prefix+)` / `prefix+(` |
| Jump straight to workspace N | `prefix+shift+N` |
| Workspace picker | `prefix+shift+t` |
| Next / previous tab | `prefix+n` / `prefix+p` |

**Alt is aerospace's namespace, not herdr's.** `alt-1..5` and `alt-b/c/f/m/o/t` are
global hotkeys that switch aerospace workspaces, so they are consumed before the
terminal sees them — a herdr binding on `alt` is dead whatever the prefix. That rules
out the `focus_agent = "prefix+alt+1..9"` the config shipped commented out.

`prefix+ctrl+N` works instead because ctrl+digit is only distinguishable under the
kitty keyboard protocol, which herdr pushes and ghostty supports. On a terminal
without it the binding would be dead.

Agents cycle on `]` and `[` rather than `tab` / `shift+tab`: terminals send Shift-Tab
as `CSI Z`, which need not match a `tab+shift` binding. A binding herdr cannot match
is disabled silently.

## Where herdr diverges from tmux

| Action | Tmux | Herdr |
|--------|------|-------|
| Rename workspace | `prefix+$` | `prefix+shift+r` |
| Workspace picker | `prefix+s` | `prefix+shift+t` |
| Resize panes | `prefix+ctrl+arrow` | `prefix+a` → `h/j/k/l` → `esc` |
| Copy mode | `prefix+[` | `prefix+v` |
| Next / previous session | `prefix+)` / `prefix+(` | same |

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
