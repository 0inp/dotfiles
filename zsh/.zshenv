# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- PATH ----------
# Shared with ~/.zprofile, which re-sources it to survive macOS `path_helper`.
# Also sets HOMEBREW_PREFIX, so it must run before anything that resolves a
# Homebrew-installed binary (vivid below, for instance).
source "$XDG_CONFIG_HOME/zsh/lib/path.zsh"

# ---------- Plugins ----------
# Defined here (not in plugins.zsh) because .zshrc needs it on FPATH before
# `compinit` runs — see the completion section in .zshrc.
export ZPLUGINDIR="$XDG_CONFIG_HOME/zsh/plugins"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="nvim"
export VISUAL="nvim"

# ---------- DOTFILES ----------
export DOTFILES="$HOME/dotfiles"

# ---------- LS_COLORS with vivid ----------
# The theme is part of the cache name: changing it makes a new cache, where a
# fixed name kept serving the old theme until the file was deleted by hand.
_vivid_theme=catppuccin-mocha
_vivid_cache="${XDG_CACHE_HOME}/zsh/ls_colors.${_vivid_theme}"
if [[ ! -f "$_vivid_cache" ]] && command -v vivid >/dev/null 2>&1; then
  mkdir -p "${_vivid_cache:h}"
  vivid generate "$_vivid_theme" > "$_vivid_cache"
fi
[[ -f "$_vivid_cache" ]] && export LS_COLORS="$(< "$_vivid_cache")"
unset _vivid_theme _vivid_cache

# ---------- OTHER SOFTWARES ----------
# bitwarden
# ssh-agent
export SSH_AUTH_SOCK=$HOME/.bitwarden-ssh-agent.sock

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# ripgrep — default flags for every `rg` invocation
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/ripgreprc"

# Brew
export HOMEBREW_NO_ENV_HINTS=1
# Makes `brew bundle --global` find this repo's Brewfile. Deliberately the
# _GLOBAL variant: plain HOMEBREW_BUNDLE_FILE would override a project's own
# ./Brewfile, whereas this one only applies when --global is passed.
export HOMEBREW_BUNDLE_FILE_GLOBAL="${XDG_CONFIG_HOME}/brewfile/Brewfile"

# Colima picks its home from ~/.colima if that exists, else $XDG_CONFIG_HOME,
# else ~/.colima. One caller without XDG (launchd, an IDE, `env -i`) therefore
# creates a second, default-sized VM in ~/.colima, which every caller then
# prefers. Pinning COLIMA_HOME makes them all agree; the scripts in
# scripts/.local/bin pin it too, since launchd never reads this file.
export COLIMA_HOME="${XDG_CONFIG_HOME}/colima"

# Testcontainers (vicat's pytest suites) doesn't read docker contexts: it wants
# /var/run/docker.sock on the Mac, which OrbStack created and Colima doesn't.
# Its Ryuk reaper then bind-mounts the DOCKER_HOST path into a container, which
# fails because that path is the Mac's, not the VM's ("mkdir ...docker.sock:
# operation not supported"); the override hands it the VM-side socket. A
# stopped VM is not started by this: run `docker ps` or `colima start` first.
export DOCKER_HOST="unix://${COLIMA_HOME}/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
