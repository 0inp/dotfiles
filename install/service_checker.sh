#!/usr/bin/env bash

set -o nounset -o pipefail -o errexit

main() {
  mkdir -p "${HOME}/opt/bin/"
  curl -o "${HOME}/opt/bin/service-checker" "https://storage.googleapis.com/ma-public-files/service-checker"
  chmod +x "${HOME}/opt/bin/service-checker"
}

main
