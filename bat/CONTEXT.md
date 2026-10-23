# bat Module Context

## Purpose
bat's config file: only the syntax theme, Catppuccin Mocha, to match ghostty.

## Key Files
| File     | Description                 | Symlink Target         |
|----------|-----------------------------|------------------------|
| `config` | Default flags for every bat | `~/.config/bat/config` |

## Notes
- Read by every bat: `cat` (alias `bat -pp`), `MANPAGER`, the fzf and `rfv`
  previews. `bat --config-file` prints the path it reads.
- delta does not read this file; `.gitconfig` sets its `syntax-theme` to the
  same name.
