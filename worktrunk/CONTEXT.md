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
- **AI Integration**: Configure AI models for commit generation
- **Post-Start Hooks**: Automated commands on workspace start

## AI Notes
- Edit `config.toml` to configure AI models and workspace behavior
- Commit generation uses OpenCode for AI-assisted commits
- Workspace hooks allow customization of startup behavior
