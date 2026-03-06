#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
  echo "macOS deteted..."

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

# Install oh-my-zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
## install zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
## install zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# ## Taps
# echo "Tapping Brew..."
# brew tap homebrew/cask-fonts
# brew tap FelixKratz/formulae
# brew install satococoa/tap/wtp

### Must Have things
# brew install zsh-autosuggestions
# brew install zsh-syntax-highlighting

## Casks
# brew install --cask karabiner-elements

## MacOS settings
echo "Changing macOS defaults..."
source ./resources/macos_settings.sh

# csrutil status
echo "Installation complete..."

# export gnu coreutils to path
# echo 'export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"' >>~/.zshrc

# Navigate to dotfiles directory
# cd $HOME/dotfiles || exit

# Stow dotfiles packages
echo "Stowing dotfiles..."
stow -t ~ .

echo "Dotfiles setup complete!"
