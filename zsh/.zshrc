# zmodload zsh/zprof

[[ -f ~/.config/zsh/completion.zsh ]] && source ~/.config/zsh/completion.zsh
[[ -f ~/.config/zsh/zinit.zsh ]] && source ~/.config/zsh/zinit.zsh
[[ -f ~/.config/zsh/functions.zsh ]] && source ~/.config/zsh/functions.zsh
[[ -f ~/.config/zsh/plugins_before.zsh ]] && source ~/.config/zsh/plugins_before.zsh
[[ -f ~/.config/zsh/env_var.zsh ]] && source ~/.config/zsh/env_var.zsh
[[ -f ~/.config/zsh/settings.zsh ]] && source ~/.config/zsh/settings.zsh
[[ -f ~/.config/zsh/aliases.zsh ]] && source ~/.config/zsh/aliases.zsh
[[ -f ~/.config/zsh/bindings.zsh ]] && source ~/.config/zsh/bindings.zsh

# Load fzf
eval "$(fzf --zsh)"

# Load Oh-My-Posh
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/.config/ohmyposh.toml)"
fi
# Load zoxide
eval "$(zoxide init zsh)"

# zprof
