# Pure prompt (sindresorhus/pure)
# Only set prompt in interactive shells
if [[ -o interactive ]]; then
  fpath+=("$HOME/.config/zsh/plugins/pure")
  # Source pure prompt - it auto-calls prompt_pure_setup
  source "$HOME/.config/zsh/plugins/pure/pure.plugin.zsh"
fi

# Settings for pure prompt (can be set in non-interactive shells too)
zstyle :prompt:pure:git:stash show yes
zstyle :prompt:pure:git:dirty detailed yes
