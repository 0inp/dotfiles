#!/bin/bash

cd "$(dirname "$0")/.."

if [[ "$(uname)" == "Darwin" ]]; then
  echo "macOS detected..."

  # Install xCode cli tools
  if xcode-select -p &>/dev/null; then
    echo "Xcode already installed"
  else
    echo "Installing commandline tools..."
    xcode-select --install
  fi

  # Install Homebrew
  if command -v brew &>/dev/null; then
    echo "Brew already installed"
  else
    echo "Installing Brew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew analytics off
  echo "Updating Brew and installing brew packages..."
  brew update
  brew upgrade
  brew bundle --file=./brew/.config/brewfile/Brewfile
  brew cleanup
  brew autoremove
fi

# Install gh-dash extension
if command -v gh &>/dev/null; then
  echo "Installing GH-Dash extension..."
  gh extension install dlvhdr/gh-dash
fi

# Setup worktrunk
if command -v wt &>/dev/null; then
  echo "Setting up worktrunk"
  wt config shell install
fi

# Install Mistral vibe CLI
if ! command -v vibe &>/dev/null; then
  echo "Installing Mistral vibe cli"
  curl -LsSf https://mistral.ai/vibe/install.sh | bash
fi

# Install TPM (Tmux Plugin Manager) only when tmux is present
if command -v tmux >/dev/null; then
  TPM_DIR="$HOME/.config/tmux/.tmux/plugins/tpm"
  if [[ -d "$TPM_DIR" ]]; then
    echo "TPM already installed"
  else
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  fi
fi

## MacOS settings
echo "Changing macOS defaults..."
source ./resources/macos_settings.sh

# csrutil status
echo "Installation complete..."

echo "Stowing dotfiles..."
stow -t ~ .

echo "Dotfiles setup complete!"
