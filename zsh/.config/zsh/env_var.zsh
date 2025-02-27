# password store
export PASSWORD_STORE_DIR=${HOME}/my_password_store
# gpg
export GPG_TTY=$(tty)
# python
export PYENV_ROOT=${HOME}/.pyenv
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

#poetry
export PATH=${HOME}/.local/bin:$PATH
# node
export PATH="/usr/local/bin:$PATH"
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Use vim as the editor
export PATH="$PATH:/opt/nvim/"
export EDITOR=nvim

# # pip should only run if there is a virtualenv currently activated
# export PIP_REQUIRE_VIRTUALENV=true

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# Docker
export DOCKER_SCAN_SUGGEST=false

# Lazygit config
export LG_CONFIG_FILE="$HOME/.config/lazygit.yaml"

# Brew
export PATH="/usr/local/sbin:$PATH"

# Golang
export PATH=$HOME/go/bin:/usr/local/go/bin:$PATH
