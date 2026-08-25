# =========================================================
# Keybindings
# =========================================================

# Cursor shape per vi mode
ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK

# Disable command mode line highlight
ZVM_VI_HIGHLIGHT_BACKGROUND=none
ZVM_VI_HIGHLIGHT_FOREGROUND=none
ZVM_VI_HIGHLIGHT_EXTRASTYLE=none

# zsh-vi-mode rebuilds the viins/vicmd keymaps at init, wiping bindings made
# earlier. Anything that must outlive that goes in this array.
#
# GOTCHA: the array name is LOWERCASE. zsh-vi-mode reads
# `zvm_after_init_commands`; the uppercase `ZVM_AFTER_INIT_COMMANDS` is not
# read by the plugin at all, so a typo here fails completely silently — the
# bindings simply never apply and nothing warns you. (The ZVM_*_MODE_CURSOR and
# ZVM_VI_HIGHLIGHT_* settings above ARE uppercase; only the command arrays are
# lowercase.) Verify with `bindkey '^g'` in a real interactive shell.

# history-substring-search bindings survive zsh-vi-mode's keymap reset
zvm_after_init_commands+=(
  "bindkey '^[[A' history-substring-search-up"
  "bindkey '^[[B' history-substring-search-down"
)


