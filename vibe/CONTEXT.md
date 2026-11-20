# vibe

Mistral Vibe CLI configuration. Stowed with tree-folding: `~/.vibe` is a
single symlink to `vibe/.vibe/`, so Vibe writes its runtime state (caches,
logs, history, plans) inside this repo directory.

## Symlink target

`~/.vibe/` → `vibe/.vibe/` (whole directory, tree-folded)

## What is versioned

`vibe/.gitignore` is an **allowlist**, same rationale as `claude/.gitignore`:
it ignores `.vibe/*` and re-includes `config.toml`, `skills/` and
`trusted_folders.toml`. A new config file needs a `!` line there.

- `config.toml`: models, providers and UI options. No API key belongs here
  (the repo is public).
- `trusted_folders.toml`: directories where Vibe skips its trust prompt.
  Accepting the prompt appends to it, so it shows up as a diff.
- `skills/`: symlinks into `agents/.agents/skills/`, with the same `..`
  counting rule as `claude/.claude/skills/` (`checks.sh symlinks`).

## Gotchas

- Vibe before 3.1.0 replaced a symlinked `config.toml` on write. That never
  bit here, since the link is the whole directory, not the file.
