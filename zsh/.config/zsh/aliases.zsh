## check if given command exists on the system
command_exists() { (( $+commands[$1] )) }


alias less='less -r'
alias vi='nvim'
alias python=python3
alias c='clear'

# ls => eza

# exchange ls with eza
command_exists "eza"
if [ "${?}" -eq "0" ]; then
  # alias ls='eza'
  alias ls="eza --color=always --long --git --icons=always --ignore-glob='*.pyc|.git|node_modules'"
  # options
  alias lsa='ls -lah'
  alias l='ls -la'
  alias ll='ls -l'
  alias lt='lsa --tree --group-directories-first'
else
  # if no eza can be used make ls colorful
  if [ "${OSTYPE}" = "linux-gnu" ]; then
    alias ls='ls --color=auto'
  elif [ "${OSTYPE}" = "darwin" ]; then
    export CLICOLOR=1
    export LSCOLORS=GxFxCxDxBxegedabagaced
  fi
fi



# exchange cd with zoxide
command_exists "zoxide"
if [ "${?}" -eq "0" ]; then
  alias cd='z'
fi
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

# lazygit
command_exists "lazygit"
if [ "${?}" -eq "0" ]; then
  alias gg=lazygit
fi

# lazydocker
command_exists "lazydocker"
if [ "${?}" -eq "0" ]; then
  alias lzd=lazydocker
fi

# fzf
command_exists "fzf"
if [ "${?}" -eq "0" ]; then
  alias al='alias | fzf'
  alias printenv='printenv | fzf'
fi

# rg
command_exists "rg"
if [ "${?}" -eq "0" ]; then
  alias rg="rg --hidden --glob '!.git'"
fi

# fdfind
command_exists "fdfind"
if [ "${?}" -eq "0" ]; then
  alias fd="fdfind"
fi
