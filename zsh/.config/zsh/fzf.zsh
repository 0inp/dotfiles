# =========================================================
# fzf
# =========================================================

# Use fd for fzf file selection
export FZF_DEFAULT_COMMAND='fd --type f --hidden --strip-cwd-prefix --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Basic fzf settings (colors only, no previews)
export FZF_DEFAULT_OPTS='
  --height=40%
  --layout=reverse
  --border=rounded
'

# =========================================================
# fzf-tab
# =========================================================

# Enable fzf-tab with minimal settings
zstyle ':fzf-tab:*' fzf-flags '--ansi'

# Basic completion colors
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Minimal completion setup
zstyle ':completion:*' menu no
zstyle ':completion:*' hidden yes

# Simple descriptions for options
zstyle ':completion:*:options' verbose yes
zstyle ':completion:*:options:*' description yes
