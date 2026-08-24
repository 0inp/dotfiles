#!/bin/bash
# Update everything this repo installs: Homebrew, runtimes, shell plugins,
# gh extensions and tmux plugins.
#
# No `set -e` here on purpose — one component being offline or broken should
# not stop the rest from updating. Each step reports its own outcome.
set -uo pipefail

echo "🚀 Starting update..."

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
ZPLUGINDIR="${ZPLUGINDIR:-$HOME/.config/zsh/plugins}"
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

# ---------- tmux plugins (TPM) ----------
echo "🖥️  Updating tmux plugins..."
TPM_UPDATE="$HOME/.config/tmux/.tmux/plugins/tpm/bin/update_plugins"
if [[ -x "$TPM_UPDATE" ]]; then
  "$TPM_UPDATE" all && echo "✅ tmux plugins updated"
else
  echo "⚠️  TPM not installed, skipping"
fi

echo "🎉 Update process completed!"
