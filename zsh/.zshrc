# zmodload zsh/zprof

# load complist zsh module
zmodload zsh/complist

# Loading of dependencies
[[ -f ~/.config/zsh/env_var.zsh ]] && source ~/.config/zsh/env_var.zsh
[[ -f ~/.config/zsh/secrets.zsh ]] && source ~/.config/zsh/secrets.zsh
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
[[ -f ~/.config/zsh/settings.zsh ]] && source ~/.config/zsh/settings.zsh
[[ -f ~/.config/zsh/bindings.zsh ]] && source ~/.config/zsh/bindings.zsh
[[ -f ~/.config/zsh/completion.zsh ]] && source ~/.config/zsh/completion.zsh
[[ -f ~/.config/zsh/zinit.zsh ]] && source ~/.config/zsh/zinit.zsh
[[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh

# Load fzf
source <(fzf --zsh)

# Prompt
autoload -U promptinit; promptinit
# turn on git stash status
zstyle :prompt:pure:git:stash show yes
prompt pure

# Load zoxide
eval "$(zoxide init zsh)"

# GPG config
gpgconf --launch gpg-agent

# zprof

# bun completions
[ -s "/Users/oinp/.bun/_bun" ] && source "/Users/oinp/.bun/_bun"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
