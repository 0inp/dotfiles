# Dotfiles
export DOTFILES="$HOME/dotfiles"

# XDG
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$XDG_CONFIG_HOME/local/share
export XDG_CACHE_HOME=$XDG_CONFIG_HOME/cache

# editor
export EDITOR="nvim"
export VISUAL="nvim"

# zsh
export HISTFILE="${HOME}/.zhistory"    # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file

# OTHER SOFTWARES
# password store
export PASSWORD_STORE_DIR=${HOME}/my_password_store

#poetry
export PATH=${HOME}/.local/bin:$PATH

# node
export PATH="/usr/local/bin:$PATH"
export NVM_DIR="${XDG_CONFIG_HOME}/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Use vim as the editor
export PATH="$PATH:/opt/nvim/"

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# Docker
export DOCKER_SCAN_SUGGEST=false

# Lazygit config
export LG_CONFIG_FILE="${XDG_CONFIG_HOME}/lazygit.yaml"

# Brew
export PATH="/usr/local/sbin:$PATH"

# Golang
export PATH=$HOME/go/bin:/usr/local/go/bin:$PATH

# PostgreSQL
export PATH="/usr/local/opt/postgresql@17/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/postgresql@17/lib"
export CPPFLAGS="-I/usr/local/opt/postgresql@17/include"

# fzf
# check if given command exists on the system
command_exists() { (( $+commands[$1] )) }

FZF_COLORS="bg+:-1,\
fg:gray,\
fg+:white,\
border:black,\
spinner:0,\
hl:yellow,\
header:blue,\
info:green,\
pointer:red,\
marker:blue,\
prompt:gray,\
hl+:red"

export FZF_DEFAULT_OPTS="--height 60% \
--border sharp \
--layout reverse \
--color '$FZF_COLORS' \
--prompt '∷ ' \
--pointer ▶ \
--marker ⇒"

export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -n 10'"

export FZF_COMPLETION_DIR_COMMANDS="cd pushd rmdir tree ls"

if command_exists "fd"; then
  export FZF_DEFAULT_COMMAND="fd . --hidden --exclude .git"
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND --type=d"
fi

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
if command_exists "bat"; then
  export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
fi
#
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
