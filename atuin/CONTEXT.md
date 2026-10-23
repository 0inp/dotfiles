# Atuin Module Context

## Purpose
Config for [atuin](https://atuin.sh), the SQLite shell history behind Ctrl-R.
Its init and keybindings live in the `zsh` module (`.zshrc`, `bindings.zsh`).

## Key Files
| File          | Description                       | Symlink Target                 |
|---------------|-----------------------------------|--------------------------------|
| `config.toml` | Non-default settings only         | `~/.config/atuin/config.toml`  |

## Notes
- The history database is in `~/.local/share/atuin/`, never in this repo.
- `keymap_mode = "auto"` matters because of zsh-vi-mode: the search opens in
  the mode the shell was in.
- Up/Down stay on zsh-history-substring-search (`--disable-up-arrow` in `.zshrc`).
