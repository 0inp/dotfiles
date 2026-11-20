# claude

Claude Code configuration. Stowed with tree-folding, so `~/.claude` is a single
symlink to `claude/.claude/` and Claude Code writes **all** of its runtime
state (projects, plugins, telemetry, history) inside this repo directory.

## Symlink targets

| Target | Source |
|---|---|
| `~/.claude/` | `claude/.claude/` (whole directory, tree-folded) |
| `~/.claude.json` | `claude/.claude.json` (machine-local, gitignored) |
| `~/.config/cd4a/config.json` | `claude/.config/cd4a/config.json` |

## What is versioned

`claude/.gitignore` is an **allowlist**: it ignores `.claude/*` and re-includes
`CLAUDE.md`, `settings.json`, `statusline-command.sh`, `hooks/`, `skills/` and
`themes/`. A new config file stays invisible to git until it gets a `!` line
there. Keep the single star: `.claude/**` would make every `!` line inert.

- `settings.json`: permissions, hooks, enabled plugins, the `dotfiles-mods`
  marketplace (`claude-mods/`, loaded from the repo, not stowed).
- `hooks/`: PreToolUse guards. `shell_commands.py` is a module the hooks
  import, not a hook. `herdr-agent-state.sh` is written by
  `herdr integration install claude`; don't hand-edit it.
- `skills/`: symlinks into `agents/.agents/skills/`. Count `..` from the
  repo path (`../../../agents/.agents/skills/<name>`), not from `~` — see
  the constraint in the root `CLAUDE.md`; `checks.sh symlinks` enforces it.
- `cd4a/config.json`: tells chrome-devtools-mcp to drive Helium. Playwright
  gets the same through `PLAYWRIGHT_MCP_EXECUTABLE_PATH` in `settings.json`.
- `skills-lock.json`: written by `npx skills`, records where each skill
  came from.

## Gotchas

- `settings.local.json` and `skills/synced/` stay out of git on purpose.
- Plugin uninstall state lives in `~/.claude/plugins/` (ignored). Removing a
  plugin from `settings.json` alone leaves it installed: also run
  `claude plugin uninstall <name>@<marketplace>`.
