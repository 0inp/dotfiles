# leaf

Terminal Markdown reader — the pane that sits beside a Claude pane when reading a
fiche.

## Symlink target
`~/.config/leaf/config.toml` → `leaf/.config/leaf/config.toml`

## Settings that differ from the defaults
- `watch = true` — reload on every save, so the pane follows an edit or an agent
  write without a keypress.
- `editor = "nvim +{$line}"` — `Ctrl+E` lands on the line leaf is showing, not on
  line 1.
- `file-history-length = 20` — the default is `0`, which disables `leaf -l` and
  `leaf -H` entirely.

## Entry points
| Command | Does |
|---|---|
| `leaf` | fuzzy picker over the Markdown files below the cwd |
| `leaf -w FILE` | open and follow on save |
| `leaf -l` / `leaf -H` | last file / history picker |
| `leaf --inline ansi FILE` | render to stdout; this is the fzf-preview form |
| `leaf --config` | edit this file |

Neovim opens it in a vsplit with `<leader>ot` (see `nvim/CONTEXT.md`).

## Constraint
`history.toml` is written next to the config and is gitignored. Today
`~/.config/leaf` is a real directory, so only `config.toml` is a symlink and the
history file never enters the repo. On a machine where that directory does not exist,
stow tree-folds the whole thing and the history file would land here instead.
