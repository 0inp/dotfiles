FZF_COLORS="bg+:-1,\
fg:gray,\
fg+:white,\
border:black,\
spinner:0,\
hl:yellow,\
header:blue,\
info:green,\
pointer:red,\
marker:blue,\
prompt:gray,\
hl+:red"

export FZF_DEFAULT_OPTS='
  --height 40%
  --layout=reverse
  --border
  --info=inline
  --margin=1
  --padding=1
  --color '$FZF_COLORS'
  --bind "ctrl-y:execute-silent(echo {} | xclip -selection clipboard)"
  --bind "ctrl-e:execute(/Users/oinp/nvim-macos-x86_64/bin/nvim {})"
'
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
export FZF_CTRL_T_OPTS="
  --preview '$show_file_or_dir_preview'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_CTRL_T_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'eza -T --color=always --all --show-symlinks {}'"
export FZF_ALT_C_COMMAND='fd . --type d --hidden --follow --exclude .git'

export FZF_COMPLETION_DIR_COMMANDS="cd pushd rmdir tree ls"

_fzf_compgen_path() {
   fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
   fd --type=d --hidden --exclude .git . "$1"
}

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo ${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}
