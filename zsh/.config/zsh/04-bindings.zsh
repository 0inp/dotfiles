# Standard and additional keybindings

# Vim style bindings (for Home/End keys...)
bindkey -v

# ctrl+b/f or ctrl+left/right: move word by word (backward/forward)
bindkey '^b' backward-word
bindkey '^f' forward-word

# Ctrl+space: print Git status
bindkey -s '^ ' ' git status --short^M'

# history search
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# Up and down arrow key support for most terminal emulators.
bindkey "^[OA" history-search-backward
bindkey "^[OB" history-search-forward
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# Disable flow control (ctrl+s, ctrl+q) to enable saving with ctrl+s in Vim
stty -ixon -ixoff
