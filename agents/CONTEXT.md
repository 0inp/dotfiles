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

## How Claude Code reaches these skills

`claude/.claude/skills/<name>` is a symlink farm into this module — one link per
skill, all pointing at `../../../agents/.agents/skills/<name>`. Three `..`, not two:
see the constraint in the root `CLAUDE.md`. Adding a skill here means adding its
link there too, or Claude Code will not see it.

## Vendored skills

`caveman` is a trimmed copy of the `skills/caveman/SKILL.md` from
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (that path is MIT;
the repo's `engine/`, `rewriter/` and friends are BSL-1.1 and are not used here).
Upstream ships it as a plugin with a SessionStart hook and a UserPromptSubmit hook
that run Node on every prompt; only the prompt text is wanted, so it is vendored
rather than installed. Upstream's `full`, `ultra` and `wenyan-*` levels are dropped
— they mangle grammar to save tokens the tokenizer does not actually charge for.
Only `lite` survives, as the single mode.

## Notes
Tool-specific skills do **not** belong here. This directory is only for skills
meant to be shared across tools. `claude/.claude/skills/` is not a second home for
them — it holds nothing but links back here (see above), so a real `SKILL.md`
committed there would be a tool-specific skill by construction. Vibe's own skills
live in `vibe/.vibe/skills/`.
