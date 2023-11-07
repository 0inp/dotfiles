## check if given command exists on the system
command_exists() { (( $+commands[$1] )) }

# Initialize completion
autoload -Uz compinit && compinit -i
zstyle ':completion:*' menu select=4
zmodload zsh/complist

# # Use vim style navigation keys in menu completion
# bindkey -M menuselect 'h' vi-backward-char
# bindkey -M menuselect 'k' vi-up-line-or-history
# bindkey -M menuselect 'l' vi-forward-char
# bindkey -M menuselect 'j' vi-down-line-or-history
#
# Initialize editing command line
autoload -U edit-command-line && zle -N edit-command-line

# Enable interactive comments (# on the command line)
setopt interactivecomments

# Nicer history
HISTSIZE=1048576
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt incappendhistory
setopt extendedhistory
setopt histignorealldups

# Time to wait for additional characters in a sequence
KEYTIMEOUT=1 # corresponds to 10ms

# fzf config
if command_exists "fd"; then
  export FZF_DEFAULT_COMMAND="fd --type f --color=never --hidden"
  export FZF_DEFAULT_OPTS="--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b"
fi

if command_exists "bat"; then
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"
fi

if command_exists "tree"; then
  export FZF_ALT_C_COMMAND="fd --type d . --color=never --hidden"
  export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"
fi
export FZF_TMUX=1

# fzf-tab zstyle completion
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with exa when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# # Use vim style line editing in zsh
# bindkey -v
# # Movement
# bindkey -a 'gg' beginning-of-buffer-or-history
# bindkey -a 'G' end-of-buffer-or-history
# # Undo
# bindkey -a 'u' undo
# bindkey -a '^R' redo
# # Edit line
# bindkey -a '^V' edit-command-line
# # Backspace
# bindkey '^?' backward-delete-char
# bindkey '^H' backward-delete-char
#
# # Use incremental search
# bindkey "^R" history-incremental-search-backward

# Disable shell builtins
disable r

# Turn off beeps
unsetopt BEEP

# Load pyenv-virtualenv
eval "$(pyenv virtualenv-init -)"


gpgconf --launch gpg-agent
ssh-add -K ~/.ssh/id\_rsa 2>/dev/null


