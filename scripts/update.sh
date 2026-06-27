#!/bin/bash

echo "🚀 Starting update..."

# Update Homebrew and packages
echo "🍺 Updating Homebrew..."
if command -v brew &>/dev/null; then
  brew update
  brew -y upgrade
  brew cleanup
  brew autoremove
  echo "✅ Homebrew updated successfully"
else
  echo "⚠️  Homebrew not installed, skipping"
fi

echo "🎉 Update process completed!"
