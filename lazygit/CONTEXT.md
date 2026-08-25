# Lazygit Module Context

## Purpose
Holds lazygit's `customCommands` only. The theme and GUI settings live in the
**`git`** module as `lazygit.yaml`.

## Key Files
| File         | Description                    | Symlink Target                 |
|--------------|--------------------------------|--------------------------------|
| `config.yml` | `customCommands` keybindings   | `~/.config/lazygit/config.yml` |

## Overlap warning
`.zshenv` sets `LG_CONFIG_FILE="$XDG_CONFIG_HOME/lazygit.yaml"`, pointing at the
`git` module's file. `LG_CONFIG_FILE` **replaces** lazygit's default config path
rather than adding to it, so the `customCommands` defined here are probably
never loaded.

To confirm: open `lazygit`, go to the local-branches panel and press `<c-p>`.
If nothing happens, this file is being ignored. Two ways to fix it if so:
- make `LG_CONFIG_FILE` a comma-separated list covering both files, or
- fold these `customCommands` into `git/.config/lazygit.yaml` and drop this
  module.

## Dependencies
- **Lazygit**: `brew install lazygit`
- `mux-new-window` from the `scripts` module (herdr-aware window opener)
