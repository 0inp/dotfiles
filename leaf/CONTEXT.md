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
| `leaf` | fuzzy picker over the Markdown files below the cwd — but see the defect below |
| `lf [QUERY]` | the picker to actually use: fd + fzf + a leaf preview |
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

## Its picker is unusable on a real tree, hence `lf`
Two independent defects, and the one that bites is not the one it prints.

`leaf --fuzzy` matches the **basename**, never the path. It displays
`docs/fiches/DEV-1937-prix-contractuel-au-lot.md` and filters on the filename
alone, which carries no `f` — so the query `fiches` returns nothing from
`docs/fiches/`, while a stray `…-fiche-de-cadrage-design.md` matches in a folder
you did not ask about.

`Indexing limited: directory limit reached` is real but is a red herring here:
it disappears when you start from `docs/` and the result does not change. Its
cause is that leaf reads no `.gitignore`, so it descends into `node_modules` —
66k directories under `~/dev/sillant`, 55k of them in one nested clone.

Neither is configurable. `LeafConfig` carries exactly nine keys (`theme`,
`editor`, `watch`, `width`, `extras`, `code-line-numbers`, `tab-title-length`,
`file-picker-width`, `file-history-length`): no limit, no exclusion, no depth.
The binary holds no trace of the `ignore` crate.

`lf` in `zsh/.config/zsh/functions.zsh` replaces it — `fd` honours `.gitignore`
(444 files in 81ms on that same tree) and fzf matches the whole path. It always
searches `$PWD`; `$1` pre-fills the query, so `lf fiches` from `~/dev/sillant`
is the intended call. The name would shadow the `lf` file manager if that ever
gets installed.
