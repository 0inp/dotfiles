# fzf Module Context

## Purpose
fzf's default options, as a file instead of a `FZF_DEFAULT_OPTS` string.

## Key Files
| File    | Description                     | Symlink Target          |
|---------|---------------------------------|-------------------------|
| `fzfrc` | Options applied to every fzf    | `~/.config/fzf/fzfrc`   |

## Notes
- Pointed at by `FZF_DEFAULT_OPTS_FILE` in `zsh/.config/zsh/fzf.zsh` (fzf 0.47+).
  The per-widget commands and previews (Ctrl-T, Alt-C) stay there too.
- fzf-tab ignores both unless `use-fzf-default-opts` is set; it is not, since
  `--height`/`--border` fight with its own popup sizing.
