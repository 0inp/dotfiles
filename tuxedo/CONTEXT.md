# tuxedo

todo.txt TUI. Reads the list that `scripts/.local/bin/sillant-daily-todo` writes.

That generator writes French, and makes the Linear ticket the `+project` — so
`lsprj` groups by ticket, not by repo, and one ticket's work across several
repos lands together. The repo carries no tag; the PR reference names it.

## Symlink target
`~/.config/tuxedo/` → `tuxedo/.config/tuxedo/` (the whole directory is tree-folded,
so anything tuxedo writes lands in this repo)

The list itself lives at `$TODO_DIR/todo.txt`, set in `.zshenv`; without that
variable a bare `tuxedo` resolves `./todo.txt` against the cwd.

## Settings
`hide_keys = "gen"` drops the `gen:<date>` tag from the task rows. That tag is what
makes regeneration idempotent — it is not meant to be read. It survives in the RAW
detail pane, which `hide_keys` deliberately does not touch.

## Constraint: tuxedo owns config.toml
The TUI rewrites this file whenever you cycle theme, density or sort, or save a
filter. Versioning those choices is the reason the directory is stowed.

Two of the keys it writes are secrets-adjacent: `share_token` and `share_port`,
added the first time you press `s` for phone capture. Anyone holding the token with
LAN reach can append to your inbox, and this repo is **public**.

Two layers keep them out:

1. **The `tuxedo-share` clean filter** (root `.gitattributes`) deletes both lines
   from what git stores; the working copy keeps them, so `git diff` never shows
   them. Its driver lives in `.git/config` and is defined by `scripts/install.sh`.
   On a clone where that never ran, the filter is a **silent no-op**: verified,
   git stages the file unfiltered with exit 0. Check with
   `git config --get filter.tuxedo-share.clean`.
2. **gitleaks** flags a `share_token` line under this repo's `.gitleaks.toml`, so
   the pre-commit hook catches what the filter missed. Do not bypass it with
   `--no-verify` on a commit that touches this file.

Everything else tuxedo writes next to the config is ignored by the allowlist in
`tuxedo/.gitignore`.
