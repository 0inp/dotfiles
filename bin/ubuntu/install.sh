#!/bin/bash

# Ensure that cheatsheet fzf script is executable
chmod +x "${HOME}/.dotfiles/resources/chtfzf.sh"

# Install apt packages
if ! [[ $(command -v apt) == "" ]]; then
	echo "apt command has been found."
	echo "Updating apt."
	sudo apt update && sudo apt upgrade
	echo "Installing all required packages."
	for i in $(cat "${HOME}/.dotfiles/ubuntu/pkglist"); do
		sudo apt-get -y install $i
	done
else
	echo "apt command do not exists. Please install it"
fi

# Install eza
if [[ $(command -v eza) == "" ]]; then
	echo "eza command not found. Installing it."
	sudo apt update
	sudo apt install -y gpg
	sudo mkdir -p /etc/apt/keyrings
	wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
	echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
	sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
	sudo apt update
	sudo apt install -y eza
else
	echo "eza command already installed."
fi

# Install glow
if [[ $(command -v glow) == "" ]]; then
	echo "glow command not found. Installing it."
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
	echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
	sudo apt update && sudo apt install glow
else
	echo "glow command already installed."
fi

# Install oh-my-posh
if [[ $(command -v oh-my-posh) == "" ]]; then
	echo "oh-my-posh command not found. Installing it."
	curl -s https://ohmyposh.dev/install.sh | bash -s
	oh-my-posh font install zedmono
else
	echo "oh-my-posh already installed."
fi

# Install lazygit
if [[ $(command -v lazygit) == "" ]]; then
	echo "lazygit command not found. Installing it."
	LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
	curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
	tar xf lazygit.tar.gz lazygit
	sudo install lazygit /usr/local/bin
else
	echo "lazygit already installed."
fi

# Install starship
if [[ $(command -v starship) == "" ]]; then
	echo "starship not found. Installing it."
	curl -sS https://starship.rs/install.sh | sh
else
	echo "starship already installed."
fi

# Install pyenv
if [[ $(command -v pyenv) == "" ]]; then
	echo "pyenv command not found. Installing it"
	curl https://pyenv.run | bash
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

# Install fzf
if [[ $(command -v fzf) == "" ]]; then
	echo "fzf not found. Installing it."
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install
else
	echo "fzf already installed."
fi

# Install neovim
if [[ $(command -v vim) == "" ]]; then
	echo "neovim not found. Installing it."
	sudo apt-get install libfuse2
	curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
	chmod u+x nvim.appimage
	./nvim.appimage
	sudo mkdir -p /opt/nvim
	sudo mv nvim.appimage /opt/nvim/nvim
else
	echo "neovim already installed."
fi

# Install Poetry
if [[ $(command -v poetry) == "" ]]; then
	echo "poetry command not found. Installing it"
	curl -sSL https://install.python-poetry.org | python3 -
else
	echo "poetry already installed."
fi

# Install pipenv
if [[ $(command -v pipenv) == "" ]]; then
	echo "pipenv not found. Installing it."
	pip install pipenv --user
else
	echo "pipenv already installed."
fi

# Install docker
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
	"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
	sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Change shell to zsh"
chsh -s $(which zsh)
echo "Shell is now : ${SHELL}"
