# claude-mods

Claude Code [mods](https://code.claude.com/docs/en/plugins/mods/overview) kept
as a local plugin marketplace, `dotfiles-mods`. **Not a stow package**:
`.stow-local-ignore` is `^.*$`, and Claude Code loads these from the repo path.

| Mod | What it does |
|---|---|
| `usage-band` | Replaces `statusLine`: two rows above the prompt. Context is coloured at 40/80; 7d by pace (usage vs elapsed share of the week), floor 5. The 5h window is not shown: Ultra drops it |

Spec: `docs/superpowers/specs/2026-10-07-claude-mods-design.md`.

## Requirements

Claude Code ≥ 2.1.287 (mods GA). Check with `claude --version`.

## Layout

Each mod: `hooks/register.ts` is thin glue over pure modules (`pace`, `layout`,
`git`). Hooks modules run with **no
Node and no DOM**, so files under `hooks/` must never import `node:*`.

## Checks

```bash
bash claude-mods/check.sh   # node --test on */tests/*.spec.ts + tsc against types/
```

`types/claude-code.d.ts` is vendored. After a Claude Code upgrade, regenerate
it with `/plugin-types` and re-run the checks.

## Dev loop

```bash
claude --plugin-dir claude-mods/usage-band
```

This loads the mod for **that one session only**, and reloads them on save.
Other sessions are untouched.

## Rollback

`usage-band`: disable it in `/plugin`, then restore in
`claude/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

`statusline-command.sh` is kept for this.
