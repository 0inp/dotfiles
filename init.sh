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
  for file in $(find ~/dotfiles/symlinks -type f); do
    basenameFile="$(echo "${file}" | sed 's/.*\(symlinks\)//g' | cut -c2-)"
    [[ -r ${file} ]] && [[ -e ${file} ]] && rm -f "${SYMLINK_PATH}/.${basenameFile}" && ln -vfs "${file}" "${SYMLINK_PATH}/.${basenameFile}"
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

main() {

  # Some files and folders need to be deleted prior the installation
  [[ -d "${HOME}/.tmux" ]] && rm -Rf ~/.tmux
  [[ -f "${HOME}/.tmux.conf" ]] && rm ~/.tmux.conf
  [[ -f "${HOME}/bin" ]] && rm ~/bin
  [[ -f "${HOME}/.gitconfig" ]] && rm ~/.gitconfig
  [[ -f "${HOME}/.pythonrc.py" ]] && rm ~/.pythonrc.py
  [[ -f "${HOME}/.zshrc" ]] && rm ~/.zshrc
  [[ -f "${HOME}/.psqlrc" ]] && rm ~/.psqlrc

  local sys=$OSTYPE; shift
  for item in zsh httpie tmux gitlint; do
    print_title "Installing $item"
    if [[ "$sys" == "linux"* ]]; then
      sudo apt -y install $item
    elif [[ "$sys" == "darwin"* ]]; then
      brew install $item
    fi
  done

  # Install browserpass on macos
  print_title "Installing Browserpass"
  if [[ "$sys" == "darwin"* ]]; then
    brew install browserpass
    PREFIX='/usr/local/opt/browserpass' make hosts-chrome-user -f /usr/local/opt/browserpass/lib/browserpass/Makefile
  fi

  # Install antigen
  print_title "Installing Antigen"
  [[ -d "${HOME}/.antigen" ]] && rm -Rf ~/.antigen
  curl -L git.io/antigen > ${HOME}/dotfiles/antigen/antigen.zsh

  # install fzf
  print_title "Installing FZF"
  [[ -d "${HOME}/.fzf" ]] && rm -Rf ~/.fzf
  git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
  ~/.fzf/install --all

  # Install neovim
  print_title "Installing Neovim"
  if [[ "$sys" == "linux"* ]]; then
    sudo apt-get install neovim
  elif [[ "$sys" == "darwin"* ]]; then
    brew install neovim
  fi
  pip3 install pynvim
  pip3 install jedi
  [[ ! -d "${HOME}/.config/nvim/" ]] && mkdir "${HOME}/.config/nvim"
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  # Ripgrep
  print_title "Installing ripgrep"
  if [[ "$sys" == "linux"* ]]; then
    curl -LO https://github.com/BurntSushi/ripgrep/releases/download/11.0.2/ripgrep_11.0.2_amd64.deb
    sudo dpkg -i ripgrep_11.0.2_amd64.deb
    rm ripgrep_11.0.2_amd64.deb
  elif [[ "$sys" == "darwin"* ]]; then
    brew install ripgrep
  fi

  # Install yamllint
  print_title "Installing yamllint"
  if [[ "$sys" == "linux"* ]]; then
    sudo apt-get install yamllint
  elif [[ "$sys" == "darwin"* ]]; then
    brew install yamllint
  fi

  # Install pgcli
  print_title "Installing pgcli"
  if [[ "$sys" == "linux"* ]]; then
    sudo apt-get install libpq-dev python-dev
    sudo pip install pgcli
  elif [[ "$sys" == "darwin"* ]]; then
    brew install pgcli
  fi

  # Switch to zsh
  print_title "Switch to ZSH"
  sudo chsh -s $(which zsh) ${USER}

  # pyenv
  print_title "Installing Pyenv Section"
  [[ -d "${HOME}/.pyenv" ]] && rm -Rf ~/.pyenv
  [[ -d "${HOME}/opt/pyenv" ]] && rm -Rf ~/opt/pyenv
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
  elif command -v pip > /dev/null 2>&1; then
    pip install --user tmuxp
  fi

  # diff-so-fancy
  print_title "Installing diff-so-fancy"
  [[ -d "${HOME}/diff-so-fancy" ]] && rm -Rf ~/diff-so-fancy
  git clone https://github.com/so-fancy/diff-so-fancy.git ~/diff-so-fancy
  export PATH="${HOME}/development/diff-so-fancy/diff-so-fancy:${PATH}"

  # MA Repos
  print_title "Cloning Repos MeilleursAgents"
  [[ ! -d "${HOME}/meilleursagents" ]] && git clone git@github.com:MeilleursAgents/MeilleursAgents.git ~/ma1
  [[ ! -d "${HOME}/MA-Infra" ]] && git clone git@github.com:MeilleursAgents/MA-Infra.git ~/MA-Infra
  [[ ! -d "${HOME}/GeoAPI" ]] && git clone git@github.com:MeilleursAgents/GeoAPI.git ~/GeoAPI
  [[ ! -d "${HOME}/IndiceAPI" ]] && git clone git@github.com:MeilleursAgents/IndiceAPI.git ~/IndiceAPI
  [[ ! -d "${HOME}/MarketAPI" ]] && git clone git@github.com:MeilleursAgents/MarketAPI.git ~/MarketAPI

  # Install gcloud
  print_title "Installing google-cloud-sdk"
  export CLOUDSDK_PYTHON=/usr/bin/python3
  if [[ "$sys" == "darwin"* ]]; then
    brew install --cask google-cloud-sdk
  fi
  gcloud components update

  # install k9s
  if [[ "$sys" == "darwin"* ]]; then
    brew install derailed/k9s/k9s
  fi
  export XDG_CONFIG_HOME=${HOME}

  # Symlinks
  print_title "Symlinks"
  create_symlinks
  [[ ! -L "${HOME}/bin" ]] && ln -s ~/dotfiles/bin ~/bin

  # Node
  print_title "Node"
  NODE_VERSION="12"
  rm -rf "${HOME}/n-install"
  git clone --depth 1 https://github.com/tj/n.git "${HOME}/n-install"
  (cd "${HOME}/n-install" && PREFIX="${HOME}/opt" make install)
  rm -rf "${HOME}/n-install"
  export PATH="${HOME}/development/opt/node/bin:${PATH}"
  export PATH="${HOME}/development/opt/bin:${PATH}"
  export N_PREFIX="${HOME}/opt"
  n "${NODE_VERSION}"
  npm install --ignore-scripts -g npm node-gyp

  # Rust
  print_title "Rust"
  if [[ ! -f "${HOME}/.cargo/bin/rustup" ]]; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  else
    rustup update
  fi

  # Cleaning
  print_title "Clean"
  clean_packages

  # Install OhMyZsh
  # keep this at the end of the script
  print_title "OhMyZsh"
  [[ -d "${HOME}/.oh-my-zsh" ]] && rm -Rf ~/.oh-my-zsh
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh > ohmyzsh.sh
  source ohmyzsh.sh --keep-zshrc
  source ~/.tmux.conf
}

main "${@:-}"
