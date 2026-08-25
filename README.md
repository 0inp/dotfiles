# Dotfiles

My dotfiles for macOS — supports both **Apple Silicon** (`/opt/homebrew`) and **Intel** (`/usr/local`) Macs.

## Installation

Make sure you have git and stow installed.

```bash
brew install git stow
```

```bash
git clone https://github.com/0inp/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x ./scripts/install.sh && ./scripts/install.sh
```

`install.sh` handles Homebrew, the Brewfile, macOS defaults and stowing. If you
ever need to run the pieces by hand:

```bash
brew bundle --global   # HOMEBREW_BUNDLE_FILE_GLOBAL points at this repo
stow -t ~ */           # one package per module directory
```

> **Never run `stow -t ~ .`** — that names the repo root as a single package and
> would symlink `aerospace/`, `brew/`, `CLAUDE.md` and `.github/` straight into
> `$HOME`, bypassing every `.stow-local-ignore`.

## Quick Start
1. Run `scripts/install.sh` to set up dotfiles.
2. Update with `scripts/update.sh`.

## Update
```bash
cd ~/dotfiles
./scripts/update.sh
```

## Directory Structure

Each top-level directory is a [GNU Stow](https://www.gnu.org/software/stow/)
package whose contents are symlinked into `~`. See
[`CONTEXT_MAP.md`](CONTEXT_MAP.md) for the full module-to-target table, and the
`CONTEXT.md` inside each module for tool-specific detail.

**Shell & terminal**
- `zsh/`: Zsh configuration (`.zshenv`, `.zprofile`, `.zshrc`, `.config/zsh/`).
- `ghostty/`: Ghostty terminal emulator.
- `herdr/`: Agent-aware terminal multiplexer (replaced tmux).
- `aerospace/`: Tiling window manager.

**Development**
- `git/`, `lazygit/`, `gh-dash/`: Git config, TUI, and PR dashboard.
- `nvim/`: Neovim, using the built-in `vim.pack` manager.
- `mise/`: Runtime version pinning (Node, Python, Go).
- `worktrunk/`: Worktree/workspace manager for parallel agent sessions.
- `ripgrep/`, `pgcli/`, `python/`, `btop/`: Per-tool configuration.

**AI agents**
- `claude/`: Claude Code settings.
- `agents/`: Cross-tool agent skills, shared via `~/.agents`.
- `vibe/`: Mistral Vibe CLI.
- `docs/agents/`: Agent skills and domain documentation.

**System**
- `brew/`: The Brewfile (packages and casks).
- `fnox/`: Secret *references* — values live in the macOS keychain.
- `gnupg/`, `launchd/`, `stats/`: GPG, LaunchAgents, menu-bar widget.
- `scripts/`: Custom scripts, symlinked into `~/.local/bin`.
- `resources/`: Helper scripts run by the installer (not stowed).

## Misc

### Command Line Tools (macOS)

Reinstall them by running following command:

```bash
sudo rm -rf $(xcode-select -print-path)
xcode-select --install
```

### Brew

Fix it with following command when it's broken.

```bash
sudo chown -R "$(whoami)" "$(brew --prefix)"/*
brew doctor
```

### Apple Silicon vs Intel

Homebrew installs to different prefixes depending on architecture:
- **Apple Silicon**: `/opt/homebrew`
- **Intel**: `/usr/local`

Scripts and shell configs use `$(brew --prefix)` or branch on `[[ -d /opt/homebrew ]]` to stay portable across both. PATH is built in `zsh/.config/zsh/lib/path.zsh`, which sets `HOMEBREW_PREFIX` by branching on the directory rather than shelling out to `brew --prefix` on every shell start.
