zmodload zsh/zprof

[[ -f ~/.config/zsh/completion.zsh ]] && source ~/.config/zsh/completion.zsh
[[ -f ~/.config/zsh/zinit.zsh ]] && source ~/.config/zsh/zinit.zsh
[[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh
[[ -f ~/.config/zsh/env_var.zsh ]] && source ~/.config/zsh/env_var.zsh
[[ -f ~/.config/zsh/settings.zsh ]] && source ~/.config/zsh/settings.zsh
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
[[ -f ~/.config/zsh/bindings.zsh ]] && source ~/.config/zsh/bindings.zsh

# Load fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Load Oh-My-Posh
eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh.toml)"

# Load zoxide
eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

zprof
