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

# ---------- PATH ----------
# Personal binaires/scripts
export PATH="$HOME/.local/bin:$PATH"

# ---------- DOTFILES ----------
export DOTFILES="$HOME/dotfiles"

# ---------- LS_COLORS with vivid ----------
_vivid_cache="${XDG_CACHE_HOME}/zsh/ls_colors"
if [[ ! -f "$_vivid_cache" ]] && command -v vivid >/dev/null 2>&1; then
  mkdir -p "${_vivid_cache:h}"
  vivid generate molokai > "$_vivid_cache"
fi
[[ -f "$_vivid_cache" ]] && export LS_COLORS="$(< "$_vivid_cache")"
unset _vivid_cache

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
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_REQUIRE_TAP_TRUST=1
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
else
  export HOMEBREW_PREFIX="/usr/local"
fi
[[ -d "$HOMEBREW_PREFIX/sbin" ]] && export PATH="$HOMEBREW_PREFIX/sbin:$PATH"

# Golang
export PATH=$HOME/go/bin:/usr/local/go/bin:$PATH
