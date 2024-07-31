# Colormap
function colormap() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

# Mean measurements of zsh loading
function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# Remove one elemant from env var PATH
function path_remove() {
  PATH=$(echo -n "$PATH" | awk -v RS=: -v ORS=: "\$0 != \"$1\"" | sed 's/:$//')
}

# Append one elemant from env var PATH
function path_append() {
  path_remove "$1"
  PATH="${PATH:+"$PATH:"}$1"
}

# Prepend one elemant from env var PATH
function path_prepend() {
  path_remove "$1"
  PATH="$1${PATH:+":$PATH"}"
}

# Add "add" argument to brew command
function brew() {
  if [[ $1 == "add" ]]; then
    # Remove the first argument ("add")
    shift
    # Install the package
    command brew install "$@"
    # Update the global Brewfile
    command brew bundle dump --global --force
  else
    # Call the original brew command with all original arguments
    command brew "$@"
  fi
}
