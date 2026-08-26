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

Every row is a stow package. Targets below were verified against the actual
symlinks in `~`, not against intent.

| Module       | Description                          | Symlink Target(s)                               |
|--------------|--------------------------------------|-------------------------------------------------|
| aerospace    | macOS window manager config          | `~/.config/aerospace/`                          |
| agents       | Cross-tool agent skills (shared)     | `~/.agents/`                                    |
| brew         | Homebrew packages and taps           | `~/.config/brewfile/`                           |
| btop         | Resource monitor (replaced htop)     | `~/.config/btop/`                               |
| claude       | Claude Code settings                 | `~/.claude/`, `~/.claude.json`                  |
| fnox         | Secret refs (values in the keychain) | `~/.config/fnox/`                               |
| gh-dash      | GitHub Dash configuration            | `~/.config/gh-dash/`                            |
| ghostty      | Ghostty terminal emulator config     | `~/.config/ghostty/`                            |
| git          | Git config **and** `lazygit.yaml`    | `~/.gitconfig`, `~/.gitignore`, `~/.config/lazygit.yaml` |
| gnupg        | GPG configuration                    | *(nothing stowed — see its CONTEXT.md)*         |
| herdr        | Agent-aware multiplexer (ex-tmux)    | `~/.config/herdr/`                              |
| launchd      | LaunchAgents (screen-recording shrink) | `~/Library/LaunchAgents/`                     |
| lazygit      | Lazygit `customCommands` only        | `~/.config/lazygit/config.yml`                  |
| mise         | Runtime versions + global npm tools  | `~/.config/mise/`                               |
| nvim         | Neovim configuration                 | `~/.config/nvim/`                               |
| pgcli        | PgCLI SQL client config              | `~/.config/pgcli/`                              |
| python       | Python REPL startup file             | `~/.pythonrc`                                   |
| ripgrep      | Default flags for `rg`               | `~/.config/ripgrep/`                            |
| scripts      | Custom scripts                       | `~/.local/bin/`                                 |
| vibe         | Mistral Vibe CLI config              | `~/.vibe/`                                      |
| worktrunk    | Worktrunk configuration              | `~/.config/worktrunk/`                          |
| zsh          | Zsh shell configuration              | `~/.zshrc`, `~/.zshenv`, `~/.zprofile`, `~/.config/zsh/` |

Not stow packages: `docs/` (agent + domain documentation) and `resources/`
(helper scripts the installer runs), both excluded via `.stow-local-ignore`.

No module for Vorssaint: it has no config file, only UserDefaults. Its settings
are declared in `scripts/.local/bin/vorssaint-apply` and pushed with `defaults
write`. It replaced Raycast (launcher, quick links) and Stats (menu bar
metrics); the old `stats/` module and its plist are in git history.

Its recorder made the old `launchd/` agent redundant — that one watched for
`.mov` and converted to `.mp4`, and the editor now saves `.mp4` directly. The
module came back for a different reason: Vorssaint cannot be configured down to
a *shareable* size. Its presets scale resolution, never bitrate, and
`recorderFrameRate` is ignored outright by the export path (declared 30, reads
back 30, every file is 60fps — verify with `ffprobe`, not `defaults read`). So
`com.oinp.screenshots-compress` re-encodes anything over 20 MB for Discord. The
original `.mov`-to-`.mp4` agent and `scripts/screenshots-to-mp4.sh` are still in
history at `46fb86e^`.

### Known overlap: lazygit is split across two modules
`git/` owns `~/.config/lazygit.yaml` (theme and GUI settings; `.zshenv` points
`LG_CONFIG_FILE` at it) while `lazygit/` owns `~/.config/lazygit/config.yml`
(only `customCommands`). Because `LG_CONFIG_FILE` **replaces** lazygit's default
config path rather than adding to it, the `customCommands` in the `lazygit/`
module are probably never loaded. Unverified — press `<c-p>` on a local branch
in lazygit to find out.

## Key Files
- **`CONTEXT.md`**: Tool-specific context (purpose, key files, dependencies) in each module.
- **`CONTEXT_MAP.md`**: This file. High-level overview of the repository.

## Usage
1. **Symlinking**: Run `stow -t ~ */` from the repo root — one package per module
   directory. Never `stow -t ~ .`, which would treat the repo root as a single
   package and symlink module directories straight into `$HOME`.
2. **AI Agents**: Refer to `CONTEXT.md` in each module for tool-specific details.
3. **Updates**: Edit files in this repo, then re-run `stow` to update symlinks.
