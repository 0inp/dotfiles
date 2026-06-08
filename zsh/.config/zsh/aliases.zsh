# =========================================================
# Core utilities
# =========================================================

alias c='clear'

# ls -> eza

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

alias ls="eza --sort=name --group-directories-first --color=always --long --git --icons=always --git-ignore"
alias la="eza -lah --sort=name --group-directories-first --color=always --long --git --icons=always --git-ignore"
alias lt="eza -lah --tree --sort=name --group-directories-first --color=always --long --git --icons=always --git-ignore"

# cat -> bat
alias cat='bat -pp'
alias less='bat --paging=always'
# override MANPAGER
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

alias grep="rg --color=auto --smart-case --hidden --glob '!.git'"
alias diff='diff --color=auto'
alias df='df -h'

# ssh
alias ssh='TERM=xterm ssh'

# IP address
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# =========================================================
# Navigation
# =========================================================
alias cd='z'
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# =========================================================
# Editor
# =========================================================
alias vim='nvim'
alias vi='nvim'

# =========================================================
# FZF
# =========================================================
alias al='alias | fzf'
alias printenv='printenv | fzf'

# =========================================================
# Git
# =========================================================
alias g='git'
alias gg="lazygit"
alias ghd='gh dash'
alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias wsa='wt switch --create --execute=opencode'

# =========================================================
# Docker
# =========================================================
alias lzd=lazydocker

# =========================================================
# LazySql
# =========================================================
alias ss=lazysql

# =========================================================
# Update dotfiles
# =========================================================
alias dotup='cd ${HOME}/dotfiles && ./scripts/update.sh && cd -'

# =========================================================
# Arr Stack Management
# =========================================================
alias arron='docker compose -f ~/dev/arr-stack/docker-compose.yml up -d'
alias arroff='docker compose -f ~/dev/arr-stack/docker-compose.yml down'
