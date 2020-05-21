#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

main() {
  local PACKAGES=('bash' 'bash-completion' 'htop' 'git' 'openssl' 'curl' 'vim' 'ncdu')

  if [[ ${OSTYPE} =~ ^darwin ]]; then
    local SCRIPT_DIR
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if ! command -v brew > /dev/null 2>&1; then
      mkdir "${HOME}/homebrew" && curl -q -sSL --max-time 300 "https://github.com/Homebrew/brew/tarball/master" | tar xz --strip 1 -C "${HOME}/homebrew"
      source "${SCRIPT_DIR}/../sources/_homebrew"
    fi

    brew update
    brew upgrade
    brew install "${PACKAGES[@]}"

    if [[ $(grep -c "$(brew --prefix)" "/etc/shells") -eq 0 ]]; then
      echo "+-------------------------+"
      echo "| changing shell for user |"
      echo "+-------------------------+"

      echo "$(brew --prefix)/bin/bash" | sudo tee -a "/etc/shells" > /dev/null
      chsh -s "$(brew --prefix)/bin/bash" -u "$(whoami)"
    fi

    if [[ ! -f ${HOME}/.bash_profile ]]; then
      echo "+---------------------------------+"
      echo "| adding .bashrc to .bash_profile |"
      echo "+---------------------------------+"

      echo '#!/usr/bin/env bash

if [[ -f "${HOME}/.bashrc" ]]; then
  source ${HOME}/.bashrc
fi' > "${HOME}/.bash_profile"
    fi
  elif command -v apt-get > /dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive

    sudo apt-get update
    sudo apt-get upgrade -y -qq
    sudo apt-get install -y -qq apt-transport-https
    sudo apt-get install -y -qq "${PACKAGES[@]}" dnsutils
  fi
}

main
