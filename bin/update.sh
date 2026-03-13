#!/bin/bash

# Comprehensive Update Script for Dotfiles
# Updates brew, dotfiles, and OpenAgents framework

echo "🚀 Starting comprehensive update..."

# Update Homebrew and packages
echo "🍺 Updating Homebrew..."
if command -v brew &> /dev/null; then
    brew update
    brew upgrade
    brew cleanup
    brew autoremove
    echo "✅ Homebrew updated successfully"
else
    echo "⚠️  Homebrew not installed, skipping"
fi

# Update dotfiles repository
echo "📂 Updating dotfiles repository..."
cd "${HOME}/dotfiles" || { 
    echo "❌ Error: Could not navigate to dotfiles directory"
    exit 1
}

# Check for unstaged changes
git status --porcelain > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "⚠️  Skipping dotfiles repository update (you have in-progress changes)"
    DOTFILES_SKIPPED=1
else
    # No unstaged changes, proceed with pull
    git pull origin main
    if [ $? -eq 0 ]; then
        echo "✅ Dotfiles repository updated"
    else
        echo "❌ Error: Failed to update dotfiles repository"
        exit 1
    fi
fi

# Update OpenAgents Framework
echo "🤖 Updating OpenAgents Framework..."
if [ -d "opencode/.opencode" ]; then
    "${HOME}/dotfiles/bin/update_opencode.sh"
else
    echo "⚠️  OpenAgents framework not found, skipping"
fi

# Reapply stow configurations
echo "🔗 Reapplying stow configurations..."
stow -R */
if [ $? -eq 0 ]; then
    echo "✅ Stow configurations reapplied"
else
    echo "❌ Error: Failed to reapply stow configurations"
    exit 1
fi

echo "🎉 Update process completed!"
echo ""
echo "Summary:"
echo "  ✅ Homebrew packages updated"
if [ -n "$DOTFILES_SKIPPED" ]; then
    echo "  ⚠️  Dotfiles repository skipped (in-progress changes)"
else
    echo "  ✅ Dotfiles repository updated"
fi
echo "  ✅ OpenAgents framework updated"
echo "  ✅ Stow configurations reapplied"
echo ""
echo "Your development environment is now up to date! 🚀"