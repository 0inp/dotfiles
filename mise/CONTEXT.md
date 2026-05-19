# Mise Module Context

## Purpose
Configuration for [Mise](https://mise.jdx.dev/), a polyglot runtime version manager (successor to `asdf`).

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config.toml`            | Mise plugins, versions, and settings | `~/.config/mise/config.toml`       |

## Dependencies
- **Mise**: Install via Homebrew (`brew install mise`).

## Key Features
- **Runtime Management**: Install and switch between versions of tools (e.g., Node.js, Python, Ruby).
- **Plugins**: Extend Mise with community plugins.
- **Settings**: Global and project-specific configurations.

## AI Notes
- Focus on `config.toml` for plugins and versions.
- Test changes with `mise current`.