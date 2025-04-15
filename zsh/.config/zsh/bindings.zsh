# Standard and additional keybindings

# Vim style bindings (for Home/End keys...)
bindkey -v
# Edit line
bindkey -M vicmd v edit-command-line

# # In menu completion, the Return key will accept the current selected match
# bindkey -M menuselect '^M' .accept-line

# # shift-tab: go backward in menu (invert of tab)
# bindkey '^[[Z' reverse-menu-complete

# # alt-x: insert last command result
# zmodload -i zsh/parameter
# insert-last-command-output() {
#   LBUFFER+="$(eval $history[$((HISTCMD-1))])"
# }
# zle -N insert-last-command-output
# bindkey '^[x' insert-last-command-output

# ctrl+b/f or ctrl+left/right: move word by word (backward/forward)
bindkey '^b' backward-word
bindkey '^f' forward-word

# Ctrl+space: print Git status
bindkey -s '^ ' ' git status --short^M'

# # Execute the current suggestion (using zsh-autosuggestions)
# # Alt+Enter = '^[^M' on recent VTE and '^[^J' for older (Lxterminal)
# bindkey '^[^M' autosuggest-execute

# history search
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Disable flow control (ctrl+s, ctrl+q) to enable saving with ctrl+s in Vim
stty -ixon -ixoff
