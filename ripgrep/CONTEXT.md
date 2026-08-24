# ripgrep

Default flags for `rg`, loaded through `$RIPGREP_CONFIG_PATH` (set in `.zshenv`).

## Symlink target
`~/.config/ripgrep/ripgreprc` → `ripgrep/.config/ripgrep/ripgreprc`

## Why this exists
`aliases.zsh` used to define `alias grep="rg --smart-case --hidden --glob '!.git'"`.
That silently swapped a POSIX tool for one with different flags: `grep -E`
(extended regex) means `--encoding` in rg, `grep -r` doesn't exist in rg, and
`grep -w` differs. Anything pasted from a README or a Stack Overflow answer
would fail in confusing ways.

The alias is gone. `grep` is grep again; `rg` gets its defaults from this file.

## Constraint
Only put **search behaviour** flags here. Output-formatting flags (`--pretty`,
`--color`, `--context`, `--vimgrep`) break editor integrations that shell out to
`rg` and parse its stdout.
