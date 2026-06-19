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

# Docker completions
FPATH="$HOME/.docker/completions:$FPATH"

# Load completion system
autoload -Uz compinit

# Initialize completion with cached metadata file
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"

# Make completion case-insensitive
# Example: "doc" can complete to "Documents"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'  # lowercase input matches upper and lower

# =========================================================
# Fuzzy finder
# =========================================================

# fzf (works for both Intel and Apple Silicon Macs)
# Only load in interactive shells as key-bindings use zle
if [[ -o interactive ]]; then
  source "$(brew --prefix fzf)/shell/key-bindings.zsh"
  source "$(brew --prefix fzf)/shell/completion.zsh"
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
mise() {
  if ! declare -f _mise_loaded > /dev/null; then
    eval "$(command mise activate zsh)" 2>/dev/null
    _mise_loaded() { :; }  # Dummy function to mark mise as loaded
  fi
  command mise "$@"
}

# =========================================================
# Bun completions
# =========================================================
if [[ -o interactive ]]; then
  eval "$(bun completions zsh)"
fi

# =========================================================
# github CLI completions
# =========================================================
if [[ -o interactive ]]; then
  eval "$(gh completion -s zsh)"
fi


# =========================================================
# Modular Config Files
# =========================================================

for config_file (${HOME}/.config/zsh/*.zsh); do
  [[ -f ${config_file} ]] && source ${config_file}
done

