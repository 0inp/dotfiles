# Colormap
function colormap() {
  for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}

function timezsh() {
  shell=${1-$SHELL}
  for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
}

# function path_remove() {
#   PATH=$(echo -n "$PATH" | awk -v RS=: -v ORS=: "\$0 != \"$1\"" | sed 's/:$//')
# }
#
# function path_append() {
#   path_remove "$1"
#   PATH="${PATH:+"$PATH:"}$1"
# }
#
# function path_prepend() {
#   path_remove "$1"
#   PATH="$1${PATH:+":$PATH"}"
# }
#
# function here() {
#   local loc
#   if [ "$#" -eq 1 ]; then
#     loc=$(realpath "$1")
#   else
#     loc=$(realpath ".")
#   fi
#   ln -sfn "${loc}" "$HOME/.shell.here"
#   echo "here -> $(readlink $HOME/.shell.here)"
# }
#
# there="$HOME/.shell.here"
#
# function there() {
#   cd "$(readlink "${there}")"
# }

function dfu() {
  cd ~/.dotfiles && git pull --ff-only && ./install -q
}
