#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

print_title() {
  local line="--------------------------------------------------------------------------------"

  printf "%s%s%s\n" "+-" "${line:0:${#1}}" "-+"
  printf "%s%s%s\n" "| " "${1}" " |"
  printf "%s%s%s\n" "+-" "${line:0:${#1}}" "-+"
}

create_symlinks() {
  local SYMLINK_PATH="${HOME}"
  for file in ~/dotfiles/symlinks/*; do
    basenameFile="$(basename "${file}")"
    [[ -r ${file} ]] && [[ -e ${file} ]] && rm -f "${SYMLINK_PATH}/.${basenameFile}" && ln -s "${file}" "${SYMLINK_PATH}/.${basenameFile}"
  done
}

clean_packages() {
  if command -v brew > /dev/null 2>&1; then
    brew cleanup
  elif command -v apt-get > /dev/null 2>&1; then
    sudo apt-get autoremove -y
    sudo apt-get clean all
  fi
}

install_submodules() {
  cd ~/dotfiles
  git config -f .gitmodules --get-regexp '^submodule\..*\.path$' | while read path_key path ; do
    url_key=$(echo $path_key | sed 's/\.path/.url/')
    url=$(git config -f .gitmodules --get "$url_key")
    rm -rf $path
    git rm -r $path
    git submodule add -f $url $path
  done
  cd ~
}

main() {

  local sys=$OSTYPE; shift
  for item in zsh vim httpie ack; do
    print_title "Installing $item"
    if [[ "$sys" == "linux"* ]]; then
      sudo apt -y install $item
    elif [[ "$sys" == "darwin"* ]]; then
      brew install $item
    fi
  done
  # Install hub
  print_title "Installing hub"
  if [[ "$sys" == "darwin"* ]]; then
    brew install $item
  fi
  # The Silver Searcher Specificity
  print_title "Installing the_silver_searcher"
  if [[ "$sys" == "linux"* ]]; then
    sudo apt -y install silversearcher-ag
  elif [[ "$sys" == "darwin"* ]]; then
    brew install the_silver_searcher
  fi

  # Switch to zsh
  print_title "Switch to ZSH"
  echo "Which user ?"
  read user
  sudo chsh -s $(which zsh) $user

  print_title "Updating submodules"
  install_submodules
  cd ~/dotfiles/ && git submodule update --init

  # pyenv
  print_title "Installing Pyenv Section"
  if [[ "$sys" == "linux"* ]]; then
    curl https://pyenv.run | bash
  elif [[ "$sys" == "darwin"* ]]; then
    brew install pyenv
  fi
  export PYENV_ROOT=${HOME}/.pyenv
  [[ ! -d "${PYENV_ROOT}/plugins/pyenv-virtualenv" ]] && git clone https://github.com/pyenv/pyenv-virtualenv.git ${PYENV_ROOT}/plugins/pyenv-virtualenv

  # Tmux Plugin Manager
  print_title "Installing Tmux Section"
  [[ ! -d "${HOME}/.tmux/plugins/tpm" ]] && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
  # Tmux Session Manager
  if command -v pip3 > /dev/null 2>&1; then
    pip3 install --user tmuxp
  fi

  # install fzf
  print_title "Installing FZF"
  ~/dotfiles/fzf/install

  # Powerline-Status
  print_title "Installing powerline-status"
  pip3 install --user powerline-status
  if [[ "$sys" == "linux"* ]]; then
    sudo apt-get install fonts-powerline
  elif [[ "$sys" == "darwin"* ]]; then
    git clone https://github.com/powerline/fonts.git --depth=1
    cd fonts
    ./install.sh
    cd ..
    rm -rf fonts install --user powerline-status
  fi

  # Ripgrep
  print_title "Installing ripgrep"
  if [[ "$sys" == "linux"* ]]; then
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
    sudo dpkg -i ripgrep_11.0.2_amd64.deb
    rm ripgrep_11.0.2_amd64.deb
  elif [[ "$sys" == "darwin"* ]]; then
    brew install ripgrep
  fi

  # MA Repos
  print_title "Cloning Repos MeilleursAgents"
  [[ ! -d "${HOME}/meilleursagents" ]] && git clone git@github.com:MeilleursAgents/MeilleursAgents.git ~/ma1
  [[ ! -d "${HOME}/MA-Infra" ]] && git clone git@github.com:MeilleursAgents/MA-Infra.git ~/MA-Infra
  [[ ! -d "${HOME}/GeoAPI" ]] && git clone git@github.com:MeilleursAgents/GeoAPI.git ~/GeoAPI
  [[ ! -d "${HOME}/IndiceAPI" ]] && git clone git@github.com:MeilleursAgents/IndiceAPI.git ~/IndiceAPI
  [[ ! -d "${HOME}/MarketAPI" ]] && git clone git@github.com:MeilleursAgents/MarketAPI.git ~/MarketAPI

  # Symlinks
  print_title "Symlinks"
  create_symlinks
  [[ ! -L "${HOME}/bin" ]] && ln -s ~/dotfiles/bin ~/bin

  # Node
  print_title "Node"
  NODE_VERSION="12"
  rm -rf "${HOME}/n-install"
  git clone --depth 1 https://github.com/tj/n.git "${HOME}/n-install"
  pushd "${HOME}/n-install"
  PREFIX="${HOME}/opt" make install
  popd
  rm -rf "${HOME}/n-install"
  n "${NODE_VERSION}"
  npm install --ignore-scripts -g npm node-gyp

  # Cleaning
  print_title "Clean"
  clean_packages
}

main "${@:-}"
