# Pure prompt (sindresorhus/pure) — installed via brew
# Only set prompt in interactive shells
if [[ -o interactive ]]; then
  fpath+="$(brew --prefix)/share/zsh/site-functions"
  autoload -U promptinit; promptinit
  prompt pure
fi

# Settings for pure prompt (can be set in non-interactive shells too)
zstyle :prompt:pure:git:stash show yes
zstyle :prompt:pure:git:dirty detailed yes
