# Dotfiles
export DOTFILES="$HOME/dotfiles"

# XDG
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$XDG_CONFIG_HOME/local/share
export XDG_CACHE_HOME=$XDG_CONFIG_HOME/cache

# editor
export EDITOR="${HOME}/nvim-macos-x86_64/bin/nvim"
export VISUAL="${HOME}/nvim-macos-x86_64/bin/nvim"

# zsh
export HISTFILE="${HOME}/.zhistory"    # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file
export LS_COLORS="$(vivid generate molokai)"

# OTHER SOFTWARES
# bitwarden ssh-agent
export SSH_AUTH_SOCK=/Users/oinp/.bitwarden-ssh-agent.sock
export GPG_TTY=$(tty)

# poetry
export PATH=${HOME}/.local/bin:$PATH

# Use vim as the editor
export PATH="$PATH:/opt/nvim/"

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# Docker
export DOCKER_SCAN_SUGGEST=false

# Lazygit config
export LG_CONFIG_FILE="${XDG_CONFIG_HOME}/lazygit.yaml"

# Brew
export PATH="/usr/local/sbin:$PATH"

# Golang
export PATH=$HOME/go/bin:/usr/local/go/bin:$PATH

# PostgreSQL
export PATH="/usr/local/opt/postgresql@17/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/postgresql@17/lib"
export CPPFLAGS="-I/usr/local/opt/postgresql@17/include"
