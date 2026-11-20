# Dotfiles Context Map

This repository contains my dotfiles, organized by tool. Each directory represents the configuration for a specific tool and is symlinked into `~/` (home directory) using `stow`.

## Theme

Catppuccin Mocha everywhere (except Vicinae, on One Dark by choice): ghostty, nvim, bat and delta, vivid (`LS_COLORS`,
so eza too), btop, herdr, lazygit, gh-dash, fzf, atuin, leaf and Claude Code.
Tools without a theme name of their own use ANSI colours and follow ghostty
(pure, fast-syntax-highlighting, the Claude statusline). Font: Monaspace Neon,
unpatched, since ghostty embeds the Nerd Font symbols.

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

Every row is a stow package. Targets below were verified against the actual
symlinks in `~`, not against intent.

| Module       | Description                          | Symlink Target(s)                               |
|--------------|--------------------------------------|-------------------------------------------------|
| aerospace    | macOS window manager config          | `~/.config/aerospace/`                          |
| agents       | Cross-tool agent skills (shared)     | `~/.agents/`                                    |
| atuin        | Shell history search settings        | `~/.config/atuin/config.toml`                   |
| bat          | bat theme (Catppuccin Mocha)         | `~/.config/bat/config`                          |
| brew         | Homebrew packages and taps           | `~/.config/brewfile/`                           |
| btop         | Resource monitor (replaced htop)     | `~/.config/btop/`                               |
| colima       | Docker VM: Lima port-forward override | `~/.config/colima/_lima/_config/override.yaml` |
| claude       | Claude Code settings                 | `~/.claude/`, `~/.claude.json`, `~/.config/cd4a/` |
| fnox         | Secret refs (values in the keychain) | `~/.config/fnox/`                               |
| fzf          | fzf default options (`fzfrc`)        | `~/.config/fzf/`                                |
| gh-dash      | GitHub Dash configuration            | `~/.config/gh-dash/`                            |
| ghostty      | Ghostty terminal emulator config     | `~/.config/ghostty/`                            |
| git          | Git config                           | `~/.gitconfig`, `~/.gitignore`                  |
| gnupg        | GPG configuration                    | *(nothing stowed — see its CONTEXT.md)*         |
| herdr        | Agent-aware multiplexer (ex-tmux)    | `~/.config/herdr/`                              |
| launchd      | LaunchAgents (capture rename + shrink) | `~/Library/LaunchAgents/`                     |
| leaf         | Terminal Markdown reader             | `~/.config/leaf/config.toml`                    |
| lazygit      | Lazygit config (single file)         | `~/.config/lazygit/config.yml`                  |
| mise         | Runtime versions + global npm tools  | `~/.config/mise/`                               |
| nvim         | Neovim configuration                 | `~/.config/nvim/`                               |
| pgcli        | PgCLI SQL client config              | `~/.config/pgcli/`                              |
| python       | Python REPL startup file             | `~/.pythonrc`                                   |
| ripgrep      | Default flags for `rg`               | `~/.config/ripgrep/`                            |
| scripts      | Custom scripts                       | `~/.local/bin/`                                 |
| vibe         | Mistral Vibe CLI config              | `~/.vibe/`                                      |
| vicinae      | Launcher (⌘Space), imported settings | `~/.config/vicinae/dotfiles.jsonc`, `~/.local/share/vicinae/scripts/` |
| worktrunk    | Worktrunk configuration              | `~/.config/worktrunk/`                          |
| zsh          | Zsh shell configuration              | `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.config/zsh/` |

Not stow packages: `docs/` (agent + domain documentation), `resources/`
(helper scripts the installer runs) and `claude-mods/` (Claude Code mods,
loaded from the repo; see its CONTEXT.md), all excluded via `.stow-local-ignore`.

One tool, one job. Vorssaint did everything at once and was removed on
2026-11-12: the launcher is now **Vicinae** (`vicinae/`), menu bar metrics
**Stats**, screenshots macOS's own (⌘⇧3/4/5, to `~/Pictures/Screenshots` via
`resources/macos_settings.sh`), and screen recording **OpenScreen**. Captures
are renamed and shrunk by `launchd/` (history in its CONTEXT.md).

No module for Stats: it has no config file, only UserDefaults. Its settings
are declared in `scripts/.local/bin/stats-apply` and pushed with `defaults
write`.

## Key Files
- **`CONTEXT.md`**: Tool-specific context (purpose, key files, dependencies) in each module.
- **`CONTEXT_MAP.md`**: This file. High-level overview of the repository.

## Usage
1. **Symlinking**: Run `stow -t ~ [^.]*/` from the repo root — one package per module
   directory. Never `stow -t ~ .`, which would treat the repo root as a single
   package and symlink module directories straight into `$HOME`.
2. **AI Agents**: Refer to `CONTEXT.md` in each module for tool-specific details.
3. **Updates**: Edit files in this repo, then re-run `stow` to update symlinks.
