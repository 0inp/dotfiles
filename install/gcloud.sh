#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

main() {
  local SCRIPT_DIR
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local GCLOUD_VERSION="280.0.0"

  local OS
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  local ARCH
  ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"

  local GCLOUD_ARCHIVE="google-cloud-sdk-${GCLOUD_VERSION}-${OS}-${ARCH}.tar.gz"

  curl -q -sSL -O "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${GCLOUD_ARCHIVE}"
  rm -rf "${HOME}/opt/google-cloud-sdk"
  tar -C "${HOME}/opt" -xzf "${GCLOUD_ARCHIVE}"
  rm -rf "${GCLOUD_ARCHIVE}"

  source "${SCRIPT_DIR}/../sources/gcloud"

  if command -v gcloud > /dev/null 2>&1; then
    gcloud components update --quiet
  fi
}

main
