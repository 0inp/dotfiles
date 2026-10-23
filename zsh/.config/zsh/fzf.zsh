# =========================================================
# fzf
# =========================================================

# fd for both widgets: it honours .gitignore, which fzf's own walker (Alt-C's
# default) does not.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --strip-cwd-prefix --exclude .git'

# Layout and colours live in the fzf module (~/.config/fzf/fzfrc).
export FZF_DEFAULT_OPTS_FILE="$XDG_CONFIG_HOME/fzf/fzfrc"

# Previews: the file for Ctrl-T (ctrl-/ cycles the preview window), the tree
# for Alt-C.
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons=always {} | head -200'"

# =========================================================
# fzf-tab
# =========================================================

# Enable fzf-tab with minimal settings
zstyle ':fzf-tab:*' fzf-flags '--ansi'
# Named groups (options, files, commands…), switched with < and >. Without the
# descriptions format, fzf-tab has no group names to switch between.
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'
# A directory's contents while completing cd (zoxide's cd included).
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

# Basic completion colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Minimal completion setup
zstyle ':completion:*' menu no

# Simple descriptions for options
zstyle ':completion:*:options' verbose yes
zstyle ':completion:*:options:*' description yes
