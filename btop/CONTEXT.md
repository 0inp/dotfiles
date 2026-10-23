# Btop Module Context

## Purpose
Configuration for [btop](https://github.com/aristocratos/btop), a resource
monitor showing CPU, memory, disks, network and processes. Replaced `htop`.

## Key Files
| File         | Description                    | Symlink Target            |
|--------------|--------------------------------|---------------------------|
| `btop.conf`  | Layout, theme and behaviour    | `~/.config/btop/`         |

Stow links the whole `~/.config/btop` directory, so btop's runtime `themes/`
subdirectory lands inside the repo if you ever download one.

## Dependencies
- **btop**: `brew install btop`

## Key Features
- **Theme**: `catppuccin_mocha`, catppuccin/btop's official file vendored in
  `themes/` (btop ships no Catppuccin), with `theme_background = False` for
  Ghostty's transparent background.
- **Vim keys**: `vim_keys = True` — `hjkl` navigation, consistent with the
  zsh-vi-mode and Neovim setup.

## Gotcha
**`save_config_on_exit = false`.** Left on, btop rewrites `btop.conf` on every
exit, through the symlink, into this repo: an unstaged diff after any change
made in the TUI. A setting tried in the TUI is now lost on quit; to keep it,
edit `btop.conf` here.

**GPU box**: `gpu0` in `shown_boxes` is the Apple Silicon GPU (btop 1.4.7+).

## AI Notes
- Bundled themes live in `$(brew --prefix btop)/share/btop/themes/`.
- Test changes by launching `btop`. It needs a real TTY; it exits with
  "Failed to get size of terminal!" when run from a non-interactive shell.
