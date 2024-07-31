# Ensure that cheatsheet fzf script is executable
chmod +x "${HOME}/dotfiles/resources/chtfzf.sh"

# Ensure that bin scripts are executable
chmod +x "${HOME}/dotfiles/bin/install.sh"
chmod +x "${HOME}/dotfiles/bin/update.sh"

# Applying MacOS default settings
chmod +x "${HOME}/dotfiles/resources/macos_settings.sh"
$HOME/dotfiles/resources/macos_settings.sh

# Install HomeBrew
if [[ $(command -v brew) == "" ]]; then
	echo "brew command not found. Installing it"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
	echo "brew command exists. Doesn't need to install it"
fi
brew bundle install --file=~/.config/brewfile/Brewfile

# Install pyenv
if [[ $(command -v pyenv) == "" ]]; then
	echo "pyenv command not found. Installing it"
	brew install ncurses
	brew install pyenv
else
	echo "pyenv command exists. Doesn't need to install it"
fi
# Install Python
if [[ $(command -v python) == "" ]]; then
	echo "python command not found. Installing it"
	pyenv install -s && head -n 1 ~/.python-version | xargs pyenv global
else
	echo "python command exists. Doesn't need to install it"
fi

# Install Poetry
if [[ $(command -v poetry) == "" ]]; then
	echo "poetry command not found. Installing it"
	curl -sSL https://install.python-poetry.org | python3 -
else
	echo "poetry command exists. Doesn't need to install it"
fi

# Configuring Browserpass extension
if [[ $(command -v make) == "" ]]; then
	echo "make command not found. Can not configure browserpass extension"
	curl -sSL https://install.python-make.org | python3 -
else
	echo "make command exists. Configuring browserpass extension"
fi
PREFIX="/usr/local/opt/browserpass" make hosts-arc-user -f /usr/local/opt/browserpass/lib/browserpass/Makefile
