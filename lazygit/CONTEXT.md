# Lazygit Module Context

## Purpose
The whole lazygit config: theme, GUI settings, the delta diff renderer and the
`customCommands`.

## Key Files
| File         | Description             | Symlink Target                 |
|--------------|-------------------------|--------------------------------|
| `config.yml` | The single config file  | `~/.config/lazygit/config.yml` |

## Gotchas
- Found through `XDG_CONFIG_HOME` (set in `.zshenv`); without it lazygit looks
  in `~/Library/Application Support/lazygit` on macOS.
- Never set `LG_CONFIG_FILE`. It **replaces** this path instead of adding to it:
  that is how the `<c-p>` command sat dead for months while a second file in the
  `git` module held the theme. Check with `lazygit --print-config-dir`.
- Do not write `subprocess: false` on a custom command. lazygit migrates that
  key away and rewrites the file on disk, through the symlink, into the repo.

## Dependencies
- **Lazygit**: `brew install lazygit`
- `mux-new-window` from the `scripts` module (herdr-aware window opener)
