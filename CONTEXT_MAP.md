# Dotfiles Context Map

This repository contains my dotfiles, organized by tool. Each directory represents the configuration for a specific tool and is symlinked into `~/` (home directory) using `stow`.

## Purpose
- **Modularity**: Each tool's configuration is isolated in its own directory.
- **AI-Navigability**: Context files (`CONTEXT.md`) in each module provide tool-specific details, reducing token usage for agents.
- **Symlink Targets**: Configurations are symlinked to their expected locations in `~/`.

## Structure
| Module       | Description                          | Symlink Target(s)               |
|--------------|--------------------------------------|----------------------------------|
| aerospace    | macOS window manager config          | `~/.config/aerospace/`           |
| brew         | Homebrew packages and taps           | `~/.Brewfile`                    |
| git          | Git configuration                    | `~/.gitconfig`, `~/.gitignore`   |
| ghostty      | Ghostty terminal emulator config     | `~/.config/ghostty/`             |
| gnupg        | GPG configuration                    | `~/.gnupg/`                      |
| htop         | Htop process viewer config           | `~/.config/htop/`                |
| litecli      | LiteCLI SQL client config            | `~/.config/litecli/`             |
| mise         | Mise version manager config          | `~/.config/mise/`                |
| nvim         | Neovim configuration                 | `~/.config/nvim/`                |
| pgcli        | PgCLI SQL client config              | `~/.config/pgcli/`               |
| python       | Python environment config            | `~/.config/python/`              |
| scripts      | Custom scripts                       | `~/.local/bin/`                  |
| stats        | macOS stats widget config            | `~/.config/stats/`               |
| tmux         | Tmux terminal multiplexer config     | `~/.config/tmux/`                |
| zsh          | Zsh shell configuration              | `~/.zshrc`, `~/.config/zsh/`     |

## Key Files
- **`CONTEXT.md`**: Tool-specific context (purpose, key files, dependencies) in each module.
- **`CONTEXT_MAP.md`**: This file. High-level overview of the repository.

## Usage
1. **Symlinking**: Use `stow` to symlink configurations to `~/`.
2. **AI Agents**: Refer to `CONTEXT.md` in each module for tool-specific details.
3. **Updates**: Edit files in this repo, then re-run `stow` to update symlinks.