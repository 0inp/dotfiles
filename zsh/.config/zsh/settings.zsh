# Vim mode
bindkey -v

# Initialize editing command line
autoload -Uz edit-command-line 
zle -N edit-command-line

# Enable interactive comments (# on the command line)
setopt interactivecomments

# History
HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt extended_history          # Write the history file in the ':start:elapsed;command' format.
setopt hist_expire_dups_first    # Expire a duplicate event first when trimming history.
setopt hist_find_no_dups         # Do not display a previously found event.
setopt hist_ignore_all_dups      # Delete an old recorded event if a new event is a duplicate.
setopt hist_ignore_dups          # Do not record an event that was just recorded again.
setopt hist_ignore_space         # Do not record an event starting with a space.
setopt hist_save_no_dups         # Do not write a duplicate event to the history file.
setopt hist_verify               # Do not execute immediately upon history expansion.etopt hist_find_no_dups
setopt sharehistory             # Share history between all sessions.

# Time to wait for additional characters in a sequence
KEYTIMEOUT=1 # corresponds to 10ms

# Bat Settings
export BAT_THEME="Dracula"

# Turn off beeps
unsetopt BEEP
