# =========================================================
# GPG
# =========================================================

export GPG_TTY=$TTY

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_FIND_NO_DUPS

# =========================================================
# Shell behaviour
# =========================================================

setopt AUTOCD
setopt NOBEEP
setopt NUMERIC_GLOB_SORT  # sort file10 after file9, not after file1
setopt GLOBDOTS

# =========================================================
# Smart directory navigation
# =========================================================

# Initialize zoxide (only in interactive shells as it uses zle)
if [[ -o interactive ]]; then
  eval "$(zoxide init zsh)"
fi

# =========================================================
# Completion
# =========================================================

# Homebrew completions
FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"

# Docker completions
FPATH="$HOME/.docker/completions:$FPATH"

# zsh-completions ships ~150 completion functions as plain _* files. They must
# be on FPATH *before* compinit — plugins.zsh loads at the very end of this
# file, which is far too late for compinit to ever see them.
[[ -d "$ZPLUGINDIR/zsh-completions/src" ]] && FPATH="$ZPLUGINDIR/zsh-completions/src:$FPATH"

# Load completion system
autoload -Uz compinit

# Skip the security/rescan pass (-C) for speed, but do a full compinit when the
# dump is missing, older than 24h, or predates the zsh-completions checkout
# (which is the case on the first shell after plugins are cloned).
_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump"
if [[ ! -f "$_zcompdump" ]] \
  || [[ -n "$_zcompdump"(#qN.mh+24) ]] \
  || [[ -d "$ZPLUGINDIR/zsh-completions/src" && "$_zcompdump" -ot "$ZPLUGINDIR/zsh-completions/src" ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# =========================================================
# Fuzzy finder
# =========================================================

# fzf (works for both Intel and Apple Silicon Macs)
# Only load in interactive shells as key-bindings use zle
if [[ -o interactive ]]; then
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
fi

# =========================================================
# Worktrunk completion
# =========================================================
# Only load in interactive shells as it may use zle
if [[ -o interactive ]] && command -v wt >/dev/null 2>&1; then 
  eval "$(command wt config shell init zsh)"
fi

# =========================================================
# Mise-en-place config
# =========================================================
if [[ -o interactive ]]; then
  eval "$(command mise activate zsh)"
fi

# =========================================================
# Secrets (fnox)
# =========================================================
# Resolves secrets out of the macOS login keychain into the environment, using
# ~/.config/fnox/config.toml. That file holds only *references* — the values
# live in the keychain, which is why it is safe to commit.
#
# Interactive-only: `activate` installs precmd/chpwd hooks, and the tokens are
# only needed by things launched from an interactive shell (the GitHub MCP
# server interpolates ${GITHUB_PERSONAL_ACCESS_TOKEN} when Claude Code starts).
#
# FNOX_SHELL_OUTPUT=none silences the cosmetic "fnox: +2 KEY1, KEY2" notice the
# hook prints on every new shell. Verified that it does NOT suppress real
# diagnostics: a missing secret still logs "WARN ... not found".
if [[ -o interactive ]] && command -v fnox >/dev/null 2>&1; then
  export FNOX_SHELL_OUTPUT=none
  eval "$(command fnox activate zsh)"
fi

# =========================================================
# Bun completions
# =========================================================
if [[ -o interactive ]] && command -v bun >/dev/null 2>&1; then
  _bun_comp_cache="$XDG_CACHE_HOME/zsh/bun_completion.zsh"
  if [[ ! -f "$_bun_comp_cache" ]]; then
    mkdir -p "${_bun_comp_cache:h}"
    bun completions zsh > "$_bun_comp_cache"
  fi
  source "$_bun_comp_cache"
  unset _bun_comp_cache
fi

# =========================================================
# github CLI completions
# =========================================================
if [[ -o interactive ]]; then
  _gh_comp_cache="$XDG_CACHE_HOME/zsh/gh_completion.zsh"
  if [[ ! -f "$_gh_comp_cache" ]] || [[ -n "$_gh_comp_cache"(#qN.mh+168) ]]; then
    mkdir -p "${_gh_comp_cache:h}"
    gh completion -s zsh > "$_gh_comp_cache"
  fi
  source "$_gh_comp_cache"
  unset _gh_comp_cache
fi


# =========================================================
# Modular Config Files
# =========================================================

for config_file (${HOME}/.config/zsh/*.zsh); do
  [[ -f ${config_file} ]] && source ${config_file}
done

