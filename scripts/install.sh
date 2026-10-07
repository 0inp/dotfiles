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

# Install the git hooks. lefthook.yml is committed, but the hooks it drives
# live in .git/hooks, which git never tracks — so a fresh clone has the config
# and zero enforcement until this runs. See lefthook.yml.
if command -v lefthook &>/dev/null; then
  echo "Installing git hooks..."
  lefthook install
fi

# Define the clean filter .gitattributes assigns to tuxedo's config.toml. Like
# the hooks above it lives in .git/config, which git never tracks. Until this
# runs, git stages that file unfiltered, token included, and says nothing.
# `required` only makes a failing sed abort the add instead of passing through.
git config filter.tuxedo-share.clean \
  "sed -e '/^share_token[[:space:]]*=/d' -e '/^share_port[[:space:]]*=/d'"
git config filter.tuxedo-share.smudge cat
git config filter.tuxedo-share.required true

# Point the Bitwarden CLI at the EU region — it defaults to the US server and
# `bw login` fails with a confusing "Invalid master password" otherwise. This
# setting lives in the CLI's own data.json, not in this repo, so a fresh machine
# needs it. Fails harmlessly (|| true) if an account is already logged in.
if command -v bw &>/dev/null; then
  echo "Pointing Bitwarden CLI at the EU region..."
  bw config server https://vault.bitwarden.eu >/dev/null || true
fi

# Install Mistral vibe CLI
if ! command -v vibe &>/dev/null; then
  echo "Installing Mistral vibe cli"
  curl -LsSf https://mistral.ai/vibe/install.sh | bash
fi

# Neovim ships no French spell files, and spelllang=fr,en silently degrades to
# English without them. Not committed: ~2.8 MB of opaque binary.
NVIM_SPELL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/spell"
mkdir -p "$NVIM_SPELL_DIR"
for spellfile in fr.utf-8.spl fr.utf-8.sug; do
  if [[ ! -s "$NVIM_SPELL_DIR/$spellfile" ]]; then
    echo "Fetching Neovim spell file $spellfile..."
    curl -sSLf --max-time 120 -o "$NVIM_SPELL_DIR/$spellfile" \
      "https://ftp.nluug.nl/pub/vim/runtime/spell/$spellfile" \
      || echo "⚠️  Could not fetch $spellfile — French spell check will be unavailable" >&2
  fi
done

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
