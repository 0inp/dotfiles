# dotfiles

## Installation

```bash
git clone git@github.com:MeilleursAgents/dotfiles.git ~/dotfiles
```

## Usage

```bash
cd ~/dotfiles
./install
```

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
