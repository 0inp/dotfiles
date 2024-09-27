# check if given command exists on the system
command_exists() { (( $+commands[$1] )) }

# Initialize editing command line
autoload -U edit-command-line && zle -N edit-command-line

# Enable interactive comments (# on the command line)
setopt interactivecomments

# History
HISTSIZE=5000
HISTFILE="$HOME/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Time to wait for additional characters in a sequence
KEYTIMEOUT=1 # corresponds to 10ms

# Bat Settings
export BAT_THEME="Dracula"

# FZF settings
# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"
export FZF_DEFAULT_OPTS="--color=fg:${fg},bg:${bg},hl:${purple},fg+:${fg},bg+:${bg_highlight},hl+:${purple},info:${blue},prompt:${cyan},pointer:${cyan},marker:${cyan},spinner:${cyan},header:${cyan}"

if command_exists "fd"; then
  export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type=d"
fi

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
if command_exists "bat"; then
  export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
fi

if command_exists "eza"; then
  export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
fi

_fzf_compgen_path() {
   fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
   fd --type=d --hidden --exclude .git . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}

export FZF_TMUX=1

# Disable shell builtins
disable r

# Turn off beeps
unsetopt BEEP

# # Load pyenv-virtualenv
# eval "$(pyenv virtualenv-init -)"

# GPG config
gpgconf --launch gpg-agent
# ssh-add -K ~/.ssh/id\_rsa 2>/dev/null
ssh-add -K ~/.ssh/id\_ed25519 2>/dev/null
