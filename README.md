# dotfiles


## Installation
```
git clone git@github.com:MeilleursAgents/dotfiles.git
./dotfiles/init.sh
```


## Usage
```
.~/dotfiles/init.sh
```
You can put secrets and other unshareable configuration into `${HOME}/.localrc`, which it's sourced at end of bash start.


## How does it work?
Running the `init.sh` script is doint a bunch of things:
### 1. Installing tools
It installs zsh, vim, httpie and hub

### 2. Update submodules
Run the `git submodule update --init` command. This concerns vundle, fzf and antigen.
### 3. Intalling more tools
Pyenv, fzf, tmux, etc.
### 4. Cloning repos
It clones differents repos used to work in MA (Main repo, MA-Infra, GeoAPI, MarketApi and IndiceAPI
### 5. Symlinks
Symlinks for a bunch of files
### 6. Node
Installing Node
### 7. Cleaning
`brew doctor` or `sudo apt-get autoremove -y && sudo apt-get clean all`


## Generate a SSH Key with a passphrase
```bash
ssh-keygen -t ed25519 -a 100 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_ed25519
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
