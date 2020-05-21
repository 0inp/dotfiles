# dotfiles

## Generate a SSH Key with a passphrase

```bash
ssh-keygen -t ed25519 -a 100 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519
```

## Installation

```
git clone git@github.com:MeilleursAgents/dotfiles.git
./dotfiles/init.sh
```

### Configuration

You can set following environment variables for customizing installation behavior:

* `DOTFILES_NO_NODE="true"` doesn't perform install of `install/node` file (replace `NODE` by any uppercase filename in `install/` dir)

## Usage

You can put secrets and other unshareable configuration into `${HOME}/.localrc`, which it's sourced at end of bash start.

## Ejection

All installed software are placed in `${HOME}/opt` and `${HOME}/homebrew` (on macOS). If you want to totally remove existing behavior, drop these directories.

If you want to keep binaries but use your own dotfiles, you must source the following files (in `${HOME}/.localrc` for example):

* `sources/_first`: add `${HOME}/opt/bin` to `$PATH`
* `sources/_python`: add `${HOME}/opt/python/bin` to `$PATH`, set `PYTHONUSERBASE` (where `pip` installs tools when setting `--user` flag) to `${HOME}/opt/python`
* `sources/gcloud`: add completion of gcloud CLI
* `sources/node`: config `n` to put binaries in `${HOME}/opt` and add `${HOME}/opt/node/bin` to `$PATH`
* `sources/work_ma`: useful command for dealing with instance and apps

```bash
#!/usr/bin/env bash

source "${HOME}/dotfiles/sources/_first"
source "${HOME}/dotfiles/sources/_python"
source "${HOME}/dotfiles/sources/gcloud"
source "${HOME}/dotfiles/sources/node"
source "${HOME}/dotfiles/sources/work_ma"
```

### God mode

If you don't want to rely anymore on this repo, you must install by yourself

* pyenv
* node 12
* gcloud

## Troublehsooting

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
