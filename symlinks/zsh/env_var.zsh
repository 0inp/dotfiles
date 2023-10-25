# password store
export PASSWORD_STORE_DIR=${HOME}/my_password_store
# gpg
export GPG_TTY=$(tty)
# python
export PATH=$(pyenv root)/shims:$PATH
export PYENV_ROOT=$(pyenv root)
#poetry
export PATH=${HOME}/.local/bin:$PATH
# node
export PATH="/usr/local/bin:$PATH"
# tmuxifier
export PATH="${HOME}/.tmux/plugins/tmuxifier/bin:$PATH"
export TMUXIFIER_LAYOUT_PATH=~/.tmux-windows

# Use vim as the editor
export EDITOR=nvim

# # pip should only run if there is a virtualenv currently activated
# export PIP_REQUIRE_VIRTUALENV=true

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# Docker
export DOCKER_SCAN_SUGGEST=false
