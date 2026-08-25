# Worktrunk Module Context

## Purpose
Configuration for [Worktrunk](https://github.com/worktrunk/worktrunk), a terminal-based workspace manager for AI coding sessions.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config.toml`            | Workspace and AI model configuration | `~/.config/worktrunk/config.toml` |

## Dependencies
- **Worktrunk**: Install via Homebrew (`brew install worktrunk`)

## Key Features
- **Workspace Management**: Create and switch between workspaces
- **AI Integration**: `[commit.generation]` can point at any CLI that turns a
  diff into a commit message. Currently unset, so `wt step commit` uses
  worktrunk's built-in fallback.
- **Post-Start Hooks**: Automated commands on workspace start

## Gotcha
This module went a long time **unstowed** — `~/.config/worktrunk/` simply did
not exist, so every setting here was inert while `wt config show` reported
"Not found". If a setting seems to have no effect, check the symlink before
checking the syntax:

```bash
wt config show          # should print USER CONFIG @ ~/.config/worktrunk/config.toml
stow -t ~ worktrunk
```

## AI Notes
- Edit `config.toml` to configure AI models and workspace behavior
- Workspace hooks allow customization of startup behavior
