# =========================================================
# Core utilities
# =========================================================

alias c='clear'

# ls -> eza

# eza ships its own _eza completion; `compdef eza=ls` used to override it with
# BSD ls's options. `auto`, not `always`: no ANSI or glyphs into `ls | wc`.
alias ls="eza --sort=name --group-directories-first --color=auto --long --git --icons=auto --git-ignore"
alias la="eza -lah --sort=name --group-directories-first --color=auto --long --git --icons=auto --git-ignore"
alias lt="eza -lah --tree --sort=name --group-directories-first --color=auto --long --git --icons=auto --git-ignore"

# cat -> bat
# `less` is NOT aliased to bat: `less +F` or `less -S` pasted from a doc would
# hit bat's flags, the same trap as the grep -> rg alias.
alias cat='bat -pp'
# override MANPAGER
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# NOTE: `grep` is deliberately NOT aliased to rg — their flags diverge (-E, -r,
# -w) and the alias broke pasted commands. rg's defaults live in
# ~/.config/ripgrep/ripgreprc instead (see the ripgrep module).
alias diff='diff --color=auto'
alias df='df -h'

# NOTE: `ssh` is deliberately NOT aliased to `TERM=xterm ssh` any more. Ghostty
# now handles this itself via `shell-integration-features = ...,ssh-env,
# ssh-terminfo` (see the ghostty module): it propagates TERM and installs its
# own terminfo on the remote host. Downgrading to plain `xterm` would throw
# away colours and features the remote can otherwise use.

# IP address
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# =========================================================
# Navigation
# =========================================================
# `cd` itself is zoxide: see `zoxide init --cmd cd` in .zshrc.
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="builtin cd -"

# =========================================================
# Editor
# =========================================================
alias vim='nvim'
alias vi='nvim'

# =========================================================
# FZF
# =========================================================
alias al='alias | fzf'
# A function, not an alias: `printenv HOME` must still print one variable.
printenv() {
  if (($#)); then command printenv "$@"; else command printenv | fzf; fi
}

# =========================================================
# Git
# =========================================================
alias g='git'
alias gg="lazygit"
alias ghd='gh dash'
alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias agl='bash ~/dotfiles/scripts/agent-loop.sh'

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
alias dotup='(cd ${HOME}/dotfiles && ./scripts/update.sh)'

# =========================================================
# Arr Stack Management
# =========================================================
alias arron='docker compose -f ~/dev/arr-stack/docker-compose.yml up -d'
alias arroff='docker compose -f ~/dev/arr-stack/docker-compose.yml down'
