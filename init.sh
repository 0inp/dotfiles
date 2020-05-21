#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

print_title() {
  local line="--------------------------------------------------------------------------------"

  printf "%s%s%s\n" "+-" "${line:0:${#1}}" "-+"
  printf "%s%s%s\n" "| " "${1}" " |"
  printf "%s%s%s\n" "+-" "${line:0:${#1}}" "-+"
}

create_symlinks() {
  for file in "${SCRIPT_DIR}/symlinks"/*; do
    basenameFile="$(basename "${file}")"
    [[ -r ${file} ]] && [[ -e ${file} ]] && rm -f "${SYMLINK_PATH}/.${basenameFile}" && ln -s "${file}" "${SYMLINK_PATH}/.${basenameFile}"
  done
}

install_tools() {
  local LANG="C"

  for file in "${SCRIPT_DIR}/install"/*; do
    local BASENAME_FILE
    BASENAME_FILE="$(basename ${file%.*})"
    local UPPERCASE_FILENAME
    UPPERCASE_FILENAME="$(echo "${BASENAME_FILE}" | tr "[:lower:]" "[:upper:]")"
    local DISABLE_VARIABLENAME="DOTFILES_NO_${UPPERCASE_FILENAME}"

    if [[ ${!DISABLE_VARIABLENAME:-} == "true" ]]; then
      continue
    fi

    print_title "install - ${BASENAME_FILE}"
    [[ -r ${file} ]] && [[ -x ${file} ]] && "${file}"
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
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local ARGS="${*}"
  local SYMLINK_PATH="${HOME}"

  if [[ -z "${ARGS}" ]] || [[ "${ARGS}" =~ symlinks ]]; then
    print_title "symlinks"
    create_symlinks
  fi

  set +u
  set +e
  mkdir -p "${HOME}/opt/bin"
  PS1="$" source "${SYMLINK_PATH}/.bashrc"
  set -e
  set -u

  if [[ -z ${ARGS} ]] || [[ ${ARGS} =~ install ]]; then
    print_title "install"
    install_tools
  fi

  if [[ -z ${ARGS} ]] || [[ ${ARGS} =~ clean ]]; then
    print_title "clean"
    clean_packages
  fi
}

main "${@:-}"
