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
chmod +x "${HOME}/dotfiles/scripts/install.sh" && ./scripts/install.sh
brew bundle
stow */
```

## Quick Start
1. Run `scripts/install.sh` to set up dotfiles.
2. Update with `scripts/update.sh`.

## Update
```bash
cd ~/dotfiles
./scripts/update.sh
```

## Directory Structure
- `scripts/`: Installation and update scripts.
- `opencode/`: OpenCode TUI agent configurations.
- `pi/`: Pi agent configurations.
- `brew/`: Homebrew configurations.
- `git/`: Git configurations.
- `zsh/`: Zsh shell configurations.
- `nvim/`: Neovim editor configurations.
- `tmux/`: Terminal multiplexer configurations.
- `docs/agents/`: Agent skills and domain documentation.

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

Scripts and shell configs use `$(brew --prefix)` or branch on `[[ -d /opt/homebrew ]]` to stay portable across both. The `zsh/.zshenv` already handles this for the Homebrew `sbin` PATH entry.
