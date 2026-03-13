#!/bin/bash

# OpenAgents Framework Update Script
# This script updates the OpenAgents framework to the latest version

echo "🔄 Updating OpenAgents Framework..."

# Check if OpenAgents directory exists
if [ ! -d "${HOME}/dotfiles/opencode/.opencode" ]; then
    echo "❌ Error: OpenAgents directory not found at ${HOME}/dotfiles/opencode/.opencode"
    exit 1
fi

# Navigate to the opencode directory
cd "${HOME}/dotfiles/opencode/.opencode" || { 
    echo "❌ Error: Could not navigate to OpenAgents directory"
    exit 1
}

# Run the official update script
echo "📥 Downloading latest updates..."
curl -fsSL https://raw.githubusercontent.com/darrenhinde/OpenAgentsControl/main/update.sh | bash

# Check if update was successful
if [ $? -eq 0 ]; then
    echo "✅ OpenAgents Framework updated successfully"
    
    # Update package dependencies if package.json exists
    if [ -f "package.json" ]; then
        echo "📦 Updating npm dependencies..."
        if command -v npm &> /dev/null; then
            npm update
        else
            echo "⚠️  npm not found, skipping dependency update"
        fi
    fi
    
    echo "🎉 OpenAgents Framework update complete!"
else
    echo "❌ Error: OpenAgents update failed"
    exit 1
fi