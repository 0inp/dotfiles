#!/bin/bash
# Bootstrap a fresh macOS machine from this repo.
#
# -e  abort on the first failing step rather than stowing a half-built system
# -u  treat unset variables as errors
# -o pipefail  a failure anywhere in a pipeline fails the pipeline
set -euo pipefail

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
  # Not idempotent: exits non-zero when the extension is already installed.
  gh extension install dlvhdr/gh-dash || true
fi

# Setup worktrunk
if command -v wt &>/dev/null; then
  echo "Setting up worktrunk"
  wt config shell install || true
fi

# Install Mistral vibe CLI
if ! command -v vibe &>/dev/null; then
  echo "Installing Mistral vibe cli"
  curl -LsSf https://mistral.ai/vibe/install.sh | bash
fi

## MacOS settings
echo "Changing macOS defaults..."
# Run in a subshell, not `source`: this script has unguarded `killall` calls
# that exit non-zero when the target app isn't running, which would abort the
# whole install under `set -e`.
bash ./resources/macos_settings.sh || echo "⚠️  Some macOS defaults failed to apply" >&2

# csrutil status
echo "Installation complete..."

echo "Stowing dotfiles..."
# One package per module directory. NOT `stow -t ~ .` — that names the repo
# root itself as the package, which would symlink aerospace/, brew/, CLAUDE.md
# and .github/ directly into $HOME, and would ignore every .stow-local-ignore.
stow -t ~ */

echo "Dotfiles setup complete!"
