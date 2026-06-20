# =========================================================
# GPG
# =========================================================

export GPG_TTY=$(tty)

# =========================================================
# History
# =========================================================

HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000

setopt APPEND_HISTORY
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

# Load completion system
autoload -Uz compinit

# Only regenerate the dump when it's older than 24h; otherwise skip (-C) for speed
if [[ -n "$XDG_CACHE_HOME/zsh/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
else
  compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi

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

