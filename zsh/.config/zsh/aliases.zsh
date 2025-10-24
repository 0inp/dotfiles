## check if given command exists on the system
command_exists() { (( $+commands[$1] )) }

alias less='less -r'
alias python=python3
alias c='clear'

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias -- -="cd -"

# Brew
alias bu="brew update; brew upgrade; brew cleanup; brew autoremove"

# exchange ls with eza
command_exists "eza"
if [ "${?}" -eq "0" ]; then
  # alias ls='eza'
  alias ls="eza -lah --sort=name --group-directories-first --color=always --long --git --icons=always --ignore-glob='*.pyc|.git|node_modules'"
  # options
  alias lt='ls --tree'
else
  # if no eza can be used make ls colorful
  if [ "${OSTYPE}" = "linux-gnu" ]; then
    alias ls='ls --color=auto'
  elif [ "${OSTYPE}" = "darwin" ]; then
    export CLICOLOR=1
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

# rg
command_exists "rg"
if [ "${?}" -eq "0" ]; then
  alias rg="rg --max-columns=150 --max-columns-preview --colors=line:style:bold --smart-case --hidden --glob '!.git'"
fi

# neovim
command_exists "nvim"
if [ "${?}" -eq "0" ]; then
  alias vim='nvim'
  alias nv='nvim'
  alias vi='nvim'
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

# IP address
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"

# twilio
alias tup="tup_func"
tup_func() {
  local root=~/dev/twilio-reactor
  local subdirs=(twilio-foundation-reactor twilio-com sendgrid segment)
  local orig_dir=$PWD
  echo "tup_func: Starting..."
  echo "tup_func: root = $root"
  echo "tup_func: subdirs = ${subdirs[@]}"
  echo "tup_func: orig_dir = $orig_dir"
  cd $root || { echo "tup_func: Failed to cd to $root"; return; }
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  echo "tup_func: current branch = $branch"
  if [ "$branch" = "twilio-develop" ]; then
    echo "tup_func: Already on twilio-develop, running git pull"
    git pull
  else
    echo "tup_func: In $root, checkout twilio-develop"
    git checkout twilio-develop && git pull
    echo "tup_func: In $root, switch back to $branch"
    git checkout "$branch"
  fi
  for dir in "${subdirs[@]}"; do
    echo "tup_func: Processing subdir $dir"
    cd "$root/$dir" || { echo "tup_func: Failed to cd to $root/$dir, skipping..."; continue; }
    local sub_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo "tup_func: current branch in $dir = $sub_branch"
    if [ "$sub_branch" = "twilio-develop" ]; then
      echo "tup_func: Already on twilio-develop in $dir, running git pull"
      git pull
    else
      echo "tup_func: In $root/$dir, checkout twilio-develop"
      git checkout twilio-develop && git pull
      echo "tup_func: In $root/$dir, switch back to $branch"
      git checkout "$branch"
    fi
  done
  cd "$orig_dir"
  echo "tup_func: Returned to $orig_dir"
  echo "tup_func: Done!"
}

alias run-author="java -Xms4g -Xmx4g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=45 -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005 -jar aem-author-p4502.jar"
alias run-publish="java -Xms4g -Xmx4g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=45 -XX:+ParallelRefProcEnabled -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:+UseStringDeduplication -jar aem-publish-p4503.jar"

alias mvn-all="mvn -T 1C clean install -PautoInstallSinglePackage -Dmaven.clean.failOnError=false -Djava.awt.headless=true"

alias mvn-no-test="mvn -T 1C clean install -PautoInstallSinglePackage -Dmaven.clean.failOnError=false -Djava.awt.headless=true -DskipTests -Dcheckstyle.skip"

