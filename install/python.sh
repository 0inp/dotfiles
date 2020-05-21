#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

main() {
  if ! command -v make > /dev/null 2>&1; then
    echo "make not found"
    exit
  fi

  if ! command -v gcc > /dev/null 2>&1; then
    echo "gcc not found"
    exit
  fi

  if ! command -v git > /dev/null 2>&1; then
    echo "git not found"
    exit
  fi

  local PYTHON_VERSION="3.6.5"

  if [[ ! -d "${HOME}/opt/pyenv" ]]; then
    git clone --depth 1 https://github.com/pyenv/pyenv.git "${HOME}/opt/pyenv"
  else
    (cd "${HOME}/opt/pyenv" && git pull)
  fi

  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  mkdir -p "${HOME}/opt/python"
  source "${SCRIPT_DIR}/../sources/_python"

  if command -v pyenv 1>/dev/null 2>&1; then
    if command -v apt-get > /dev/null 2>&1; then
      local HAS_LIBSSL_1
      HAS_LIBSSL_1="$(sudo dpkg -l | grep -c libssl1.0-dev)"

      sudo apt-get update -y
      sudo apt-get install -y -qq build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

      if [[ "${HAS_LIBSSL_1}" -eq 1 ]]; then
        sudo apt-get remove -y libssl-dev
        sudo apt-get install -y libssl1.0-dev
      fi
    fi

    pyenv install -s "${PYTHON_VERSION}"
    pyenv global "${PYTHON_VERSION}"
  fi
}

main
