# agents

Cross-tool agent skills, shared by every AGENTS.md-aware CLI on this machine
(Claude Code, Mistral Vibe, and anything else that reads `~/.agents/skills/`).

## Symlink target
`~/.agents/` → `agents/.agents/`

## Why this is its own module

These skills used to be duplicated in `claude/.agents/` and `vibe/.agents/`.
Both stow packages targeted `~/.agents/skills/`, which meant:

- `stow */` conflicted on a clean machine and aborted the whole install;
- whichever package stow happened to reach first silently shadowed the other
  (in practice `vibe`, so newer skills committed under `claude/` were never
  actually reachable through `~/.agents`);
- every edit had to be made twice to stay in sync, and drifted when it wasn't.

Owning the directory in a module named after the *concern* rather than after
one of its consumers removes all three problems. Neither CLI owns it.

## Key files
- `.agents/skills/<name>/SKILL.md` — the skill definition
- `.agents/skills/<name>/agents/openai.yaml` — per-provider agent config

## Notes
Tool-specific skills do **not** belong here. Claude Code's own skills live in
`claude/.claude/skills/`; Vibe's live in `vibe/.vibe/skills/`. This directory is
only for skills meant to be shared across tools.
