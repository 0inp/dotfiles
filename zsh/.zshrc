# zmodload zsh/zprof

# # load complist zsh module
# zmodload zsh/complist
#
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light zdharma-continuum/fast-syntax-highlighting

# prompt
zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit light sindresorhus/pure

zinit light wfxr/forgit

zinit light zsh-users/zsh-autosuggestions

zinit light zsh-users/zsh-completions

zinit light Aloxaf/fzf-tab
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

zinit ice as'program' atload'zicompinit'
zinit light ael-code/zsh-colored-man-pages


# Loading of dependencies
for config_file (${HOME}/.config/zsh/*.zsh); do
  [[ -f ${config_file} ]] && source ${config_file}
done

# # Load fzf
# source <(fzf --zsh)
#
# # Prompt
# autoload -U promptinit; promptinit
# # turn on git stash status
# zstyle :prompt:pure:git:stash show yes
# prompt pure

# Load zoxide
eval "$(zoxide init zsh)"

# GPG config
gpgconf --launch gpg-agent

# bun completions
[ -s "/Users/oinp/.bun/_bun" ] && source "/Users/oinp/.bun/_bun"

#setup worktrunk
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# setup mise
eval "$(mise activate zsh)"

autoload -Uz compinit
compinit

zinit cdreplay -q
# zprof
