# zmodload zsh/zprof

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load plugins LAZILY (after prompt appears)
zinit wait lucid for \
  zdharma-continuum/fast-syntax-highlighting \
  zsh-users/zsh-autosuggestions \
  wfxr/forgit

# Load pure prompt IMMEDIATELY (not lazy)
zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light sindresorhus/pure

# Load zsh-completions (before compinit, lazy)
zinit ice as"completion" wait lucid
zinit light zsh-users/zsh-completions

# Load zsh-colored-man-pages (lazy)
zinit ice as'program' atload'zicompinit' wait lucid
zinit light ael-code/zsh-colored-man-pages

# Load zoxide (lazy)
zinit ice as"command" atload"eval $(zoxide init zsh)" wait lucid
zinit light ajeetdsouza/zoxide

# Load fzf (lazy)
zinit ice as"command" atload'source <(fzf --zsh)' wait lucid
zinit light junegunn/fzf

# Load your modular configs (except 06-fzf-tab.zsh)
for config_file (${HOME}/.config/zsh/*.zsh); do
  [[ -f ${config_file} ]] && [[ ${config_file} != "${HOME}/.config/zsh/06-fzf-tab.zsh" ]] && source ${config_file}
done

# Initialize completion system (cached)
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit -C
else
  compinit
fi

zinit wait lucid for \
  atload'eval "$(command wt config shell init zsh)"' max-sixty/worktrunk

# Lazy-load mise on first use
mise() {
  if ! declare -f _mise_loaded > /dev/null; then
    # Load mise only once
    eval "$(command mise activate zsh)" 2>/dev/null
    _mise_loaded() { :; }  # Dummy function to mark mise as loaded
  fi
  command mise "$@"
}

# Load bun completions (directly, no zinit)
source "$(brew --prefix bun)/share/zsh/site-functions/_bun"

# Load fzf-tab after compinit
source "${HOME}/.config/zsh/06-fzf-tab.zsh"

zinit cdreplay -q
# zprof
