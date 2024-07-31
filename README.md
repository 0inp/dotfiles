# Dotfiles

Here are my dotfiles. They are MacOS oriented.

## Installation

Make sure you have git and stow installed.

```bash
brew install git stow
```

```bash
git clone https://github.com/0inp/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x "${HOME}/dotfiles/bin/install.sh" && ./bin/install.sh
brew bundle
stow */
```

## Update

```bash
cd ~/dotfiles
./bin/update.sh
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
