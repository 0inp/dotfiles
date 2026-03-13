# Load fzf-tab after compinit
zinit light Aloxaf/fzf-tab

# Enable dotfiles/dotdirs in completion
setopt globdots
zstyle ':completion:*' hidden yes
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]-}={[:upper:][:lower:]} r:|[._-]=* r:|=*'

# Force preview window for files and directories ONLY
zstyle ':fzf-tab:*' fzf-flags --preview-window=down:3:wrap
zstyle ':fzf-tab:complete:*:*' fzf-preview '
  if [ -f "$word" ]; then
    bat -n --color=always --line-range :50 "$word" 2>/dev/null
  elif [ -d "$word" ]; then
    eza -T --color=always --level=2 --all "$word" 2>/dev/null
  fi'

# Enable fzf-tab for Tab completion
zstyle ':fzf-tab:*' disabled-on false
bindkey '^I' fzf-tab-complete

