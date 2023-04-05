## check if given command exists on the system
command_exists() { (( $+commands[$1] )) }


alias less='less -r'
alias vi='nvim'
alias tmux='tmux -2'
alias python=python3

alias fixssh='eval $(tmux showenv -s SSH_AUTH_SOCK)'

# ls => exa

# exchange ls with exa
# https://the.exa.website/
command_exists "exa"
if [ "${?}" -eq "0" ]; then
  alias ls='exa'
else
  # if no exa can be used make ls colorful
  if [ "${OSTYPE}" = "linux-gnu" ]; then
    alias ls='ls --color=auto'
  elif [ "${OSTYPE}" = "darwin" ]; then
    export CLICOLOR=1
    export LSCOLORS=GxFxCxDxBxegedabagaced
  fi
fi

# options
alias lsa='ls -lah'
alias l='ls -la'
alias ll='ls -l'

# grep => ripgrep

# exchange grep with ripgrep
# https://github.com/BurntSushi/ripgrep
command_exists "rg"
if [ "${?}" -eq "0" ]; then
  alias grep='rg'
fi

# neovim
command_exists "nvim"
if [ "${?}" -eq "0" ]; then
  alias vim=nvim
  alias nv=nvim
fi

# git
command_exists "git"
if [ "${?}" -eq "0" ]; then
  alias g='git'
fi

# fzf
command_exists "fzf"
if [ "${?}" -eq "0" ]; then
  alias al='alias | fzf'
  alias printenv='printenv | fzf'
fi

# tmux
alias ta='tmux attach'
alias tls='tmux ls'
alias tat='tmux attach -t'
alias tns='tmux new-session -s'
