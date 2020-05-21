#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

main() {
  if command -v brew > /dev/null 2>&1; then
    brew install ripgrep
  elif command -v apt-get > /dev/null 2>&1 && [[ "$(uname -m | tr "[:upper:]" "[:lower:]")" = "x86_64" ]]; then
    local RIPGREP_VERSION="12.0.1"
    local RIPGREP_FILE="ripgrep_${RIPGREP_VERSION}_amd64.deb"

    curl -q -sSL -O "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/${RIPGREP_FILE}"
    sudo dpkg -i "${RIPGREP_FILE}"
    rm -rf "${RIPGREP_FILE}"
  fi
}

main
