# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`CONTEXT_MAP.md`** at the repo root — maps every stow module to its symlink target and its `CONTEXT.md`.
- **`<module>/CONTEXT.md`** — each top-level stow module (e.g. `zsh/`, `herdr/`, `git/`) has its own `CONTEXT.md` with tool-specific details. Read the ones relevant to the module you're touching.
- **`docs/adr/`** — repo has none today. If one gets added, read ADRs that touch the area you're about to work in.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront.

## File structure

This repo is multi-context by stow module — one `CONTEXT.md` per top-level package, indexed by a root map:

```
/
├── CONTEXT_MAP.md          ← maps every module to its symlink target
├── zsh/
│   ├── CONTEXT.md
│   └── .config/zsh/...
├── git/
│   ├── CONTEXT.md
│   └── .gitconfig
└── ...                     ← one CONTEXT.md per module (aerospace, agents,
                                brew, btop, claude, fnox, gh-dash, ghostty,
                                gnupg, herdr, launchd, mise, nvim, pgcli,
                                python, ripgrep, scripts, stats, vibe,
                                worktrunk)
```

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `CONTEXT.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/grill-with-docs`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_