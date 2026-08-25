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
- **Theme**: `gruvbox_dark_v2` with `theme_background = False`, matching the
  Ghostty `Gruvbox Dark` theme and its transparent background.
- **Vim keys**: `vim_keys = True` — `hjkl` navigation, consistent with the
  zsh-vi-mode and Neovim setup.

## Gotcha
**btop rewrites `btop.conf` on exit**, exactly like the `htoprc` it replaced.
Changing settings in the TUI edits the file in this repo through the symlink,
which shows up as an unstaged diff. That is expected — commit it or `git
checkout` it, but don't be surprised by it.

## AI Notes
- Bundled themes live in `$(brew --prefix btop)/share/btop/themes/`.
- Test changes by launching `btop`. It needs a real TTY; it exits with
  "Failed to get size of terminal!" when run from a non-interactive shell.
