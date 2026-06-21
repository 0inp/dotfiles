# Dotfiles Context Map

This repository contains my dotfiles, organized by tool. Each directory represents the configuration for a specific tool and is symlinked into `~/` (home directory) using `stow`.

## Platform Support

These dotfiles target **macOS on both Apple Silicon and Intel** Macs.

Key architectural difference to be aware of when editing any file that references Homebrew paths:

| Architecture   | Homebrew prefix       |
|----------------|-----------------------|
| Apple Silicon  | `/opt/homebrew`       |
| Intel          | `/usr/local`          |

Prefer `$(brew --prefix <pkg>)` over hardcoded paths. For performance-critical paths loaded on every shell start (`.zshenv`), check `[[ -d /opt/homebrew ]]` to branch without spawning a subprocess.

## Purpose
- **Modularity**: Each tool's configuration is isolated in its own directory.
- **AI-Navigability**: Context files (`CONTEXT.md`) in each module provide tool-specific details, reducing token usage for agents.
- **Symlink Targets**: Configurations are symlinked to their expected locations in `~/`.

## Structure
| Module       | Description                          | Symlink Target(s)               |
|--------------|--------------------------------------|----------------------------------|
| aerospace    | macOS window manager config          | `~/.config/aerospace/`           |
| brew         | Homebrew packages and taps           | `~/.Brewfile`                    |
| claude       | Claude Code settings                 | `~/.claude/`                      |
| git          | Git configuration                    | `~/.gitconfig`, `~/.gitignore`   |
| launchd      | macOS LaunchAgents for automation    | `~/Library/LaunchAgents/`        |
| ghostty      | Ghostty terminal emulator config     | `~/.config/ghostty/`             |
| gh-dash       | GitHub Dash configuration             | `~/.config/gh-dash/`              |
| gnupg        | GPG configuration                    | `~/.gnupg/`                      |
| htop         | Htop process viewer config           | `~/.config/htop/`                |
| mise         | Mise version manager config          | `~/.config/mise/`                |
| nvim         | Neovim configuration                 | `~/.config/nvim/`                |
| pgcli        | PgCLI SQL client config              | `~/.config/pgcli/`               |
| python       | Python environment config            | `~/.config/python/`              |
| scripts      | Custom scripts                       | `~/.local/bin/`                  |
| stats        | macOS stats widget config            | `~/.config/stats/`               |
| tmux         | Tmux terminal multiplexer config     | `~/.config/tmux/`                |
| vibe         | Mistral Vibe CLI config               | `~/.vibe/`                        |
| worktrunk    | Worktrunk configuration               | `~/.config/worktrunk/`            |
| zsh          | Zsh shell configuration              | `~/.zshrc`, `~/.config/zsh/`     |

## Key Files
- **`CONTEXT.md`**: Tool-specific context (purpose, key files, dependencies) in each module.
- **`CONTEXT_MAP.md`**: This file. High-level overview of the repository.

## Usage
1. **Symlinking**: Use `stow` to symlink configurations to `~/`.
2. **AI Agents**: Refer to `CONTEXT.md` in each module for tool-specific details.
3. **Updates**: Edit files in this repo, then re-run `stow` to update symlinks.
