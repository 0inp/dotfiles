# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- PATH ----------
# Personal binaires/scripts
export PATH="$HOME/.local/bin:$PATH"

# ---------- DOTFILES ----------
export DOTFILES="$HOME/dotfiles"

# ---------- LS_COLORS with vivid ----------
export LS_COLORS="$(vivid generate molokai)"

# ---------- OTHER SOFTWARES ----------
# bitwarden
# ssh-agent
export SSH_AUTH_SOCK=$HOME/.bitwarden-ssh-agent.sock

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# Docker
export DOCKER_SCAN_SUGGEST=false

# Lazygit config
export LG_CONFIG_FILE="${XDG_CONFIG_HOME}/lazygit.yaml"

# Brew
export HOMEBREW_NO_ENV_HITNS=1
export HOMEBREW_REQUIRE_TAP_TRUST=1
export PATH="/usr/local/sbin:$PATH"

# Golang
export PATH=$HOME/go/bin:/usr/local/go/bin:$PATH

# PostgreSQL
export PATH="/usr/local/opt/postgresql@17/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/postgresql@17/lib"
export CPPFLAGS="-I/usr/local/opt/postgresql@17/include"
