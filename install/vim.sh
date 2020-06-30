#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

main() {
  if ! command -v git > /dev/null 2>&1; then
    echo "git not found"
    exit
  fi

  if [[ ! -d "${HOME}/.vim/bundle" ]]; then
    rm -rf "${HOME}/.vim/bundle/Vundle.vim" && git clone https://github.com/VundleVim/Vundle.vim.git "${HOME}/.vim/bundle/Vundle.vim"
  fi
}

main
