#!/bin/bash
# Update everything this repo installs: Homebrew, runtimes, shell plugins
# and gh extensions.
#
# No `set -e` here on purpose — one component being offline or broken should
# not stop the rest from updating. Each step reports its own outcome.
set -uo pipefail

echo "🚀 Starting update..."

# A changelog is a delta, and the steps below destroy its "before" half as they
# run — once brew has upgraded, `brew outdated` is empty. So state is recorded
# up front here and diffed by cl_report at the end. See scripts/changelog.sh.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZPLUGINDIR="${ZPLUGINDIR:-$HOME/.config/zsh/plugins}"
if [[ -r "$SCRIPT_DIR/changelog.sh" ]]; then
  # shellcheck source=scripts/changelog.sh
  . "$SCRIPT_DIR/changelog.sh"
  cl_snapshot
else
  cl_report() { :; }
fi

# ---------- Homebrew ----------
echo "🍺 Updating Homebrew..."
if command -v brew &>/dev/null; then
  brew update
  brew upgrade -y
  brew cleanup
  brew autoremove
  echo "✅ Homebrew updated successfully"
else
  echo "⚠️  Homebrew not installed, skipping"
fi

# ---------- Runtimes (mise) ----------
echo "🧰 Updating mise-managed runtimes..."
if command -v mise &>/dev/null; then
  mise upgrade
  mise prune --yes
  echo "✅ mise runtimes updated"
  mise current
else
  echo "⚠️  mise not installed, skipping"
fi

# ---------- Zsh plugins ----------
# Mirrors the `zplugin-update` function in zsh/.config/zsh/plugins.zsh, inlined
# here because that function is zsh-only and this script runs under bash.
echo "🔌 Updating zsh plugins..."
if [[ -d "$ZPLUGINDIR" ]]; then
  for dir in "$ZPLUGINDIR"/*/; do
    [[ -d "$dir/.git" ]] || continue
    echo "  → $(basename "$dir")"
    git -C "$dir" pull --ff-only --quiet || echo "  ⚠️  $(basename "$dir") failed to update"
  done
  echo "✅ Zsh plugins updated"
else
  echo "⚠️  No plugin dir at $ZPLUGINDIR, skipping"
fi

# ---------- gh extensions ----------
echo "🐙 Updating gh extensions..."
if command -v gh &>/dev/null; then
  gh extension upgrade --all && echo "✅ gh extensions updated"
else
  echo "⚠️  gh not installed, skipping"
fi

echo "🎉 Update process completed!"

cl_report
