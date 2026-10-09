#!/usr/bin/env bash
# Pure-logic specs (node --test) and a type-check of every hooks module against
# the vendored mods types. Runs without Claude Code, so it works on any version.
set -euo pipefail
cd "$(dirname "$0")"

shopt -s nullglob
specs=(*/tests/*.spec.ts)
if ((${#specs[@]})); then
  node --test "${specs[@]}"
fi
tsc -p tsconfig.json
