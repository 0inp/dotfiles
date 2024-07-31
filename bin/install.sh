# Ensure that cheatsheet fzf script is executable
chmod +x "${HOME}/dotfiles/resources/chtfzf.sh"

# Ensure that bin scripts are executable
chmod +x "${HOME}/dotfiles/bin/install.sh"
chmod +x "${HOME}/dotfiles/bin/install.sh"

# Applying MacOS default settings
chmod +x "${HOME}/dotfiles/resources/macos_settings"
$HOME/dotfiles/resources/macos_settings.sh

# Install HomeBrew
if [ ! "$(which "brew")" != "" ]; then
	echo "brew command exists. Doesn't need to install it"
else
	echo "brew command not found. Installing it"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# Install pyenv
if [ ! "$(which "pyenv")" != "" ]; then
	echo "pyenv command exists. Doesn't need to install it"
else
	echo "pyenv command not found. Installing it"
	brew install ncurses
	brew install pyenv
fi
# Install Python
if [ ! "$(which "python")" != "" ]; then
	echo "python command exists. Doesn't need to install it"
else
	echo "python command not found. Installing it"
	pyenv install -s && head -n 1 ~/.python-version | xargs pyenv global
fi

# Install Poetry
if [ ! "$(which "poetry")" != "" ]; then
	echo "poetry command exists. Doesn't need to install it"
else
	echo "poetry command not found. Installing it"
	curl -sSL https://install.python-poetry.org | python3 -
fi

# Configuring Browserpass extension
if [ ! "$(which "make")" != "" ]; then
	echo "make command exists. Configuring browserpass extension"
else
	echo "make command not found. Can not configure browserpass extension"
	curl -sSL https://install.python-make.org | python3 -
fi
PREFIX='/usr/local/opt/browserpass' make hosts-chrome-user -f /usr/local/opt/browserpass/lib/browserpass/Makefile,
