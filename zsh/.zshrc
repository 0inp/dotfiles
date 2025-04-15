# zmodload zsh/zprof

# load complist zsh module
zmodload zsh/complist

# Loading of dependencies
[[ -f ~/.config/zsh/env_var.zsh ]] && source ~/.config/zsh/env_var.zsh
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
[[ -f ~/.config/zsh/settings.zsh ]] && source ~/.config/zsh/settings.zsh
[[ -f ~/.config/zsh/bindings.zsh ]] && source ~/.config/zsh/bindings.zsh
[[ -f ~/.config/zsh/completion.zsh ]] && source ~/.config/zsh/completion.zsh
[[ -f ~/.config/zsh/zinit.zsh ]] && source ~/.config/zsh/zinit.zsh
[[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh

# Load fzf
source <(fzf --zsh)

# Load Oh-My-Posh
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh.toml)"

# Load zoxide
eval "$(zoxide init zsh)"

# GPG config
gpgconf --launch gpg-agent
# ssh-add ~/.ssh/id\_ed25519 2>/dev/null

# zprof
