# =========================================================
# PATH construction
# =========================================================
# Sourced from BOTH ~/.zshenv (so non-login, non-interactive shells get a
# usable PATH) and ~/.zprofile (so macOS's /etc/zprofile `path_helper` cannot
# demote these entries below /usr/local/bin and /usr/bin). Re-sourcing is safe:
# `typeset -U` keeps `path` deduplicated and re-asserts the preferred order.
#
# Deliberately NOT named ~/.config/zsh/*.zsh — .zshrc globs that directory, and
# re-running this file after `mise activate` would hoist Homebrew above the mise
# shims and defeat runtime version pinning.

# Keep `path` (and the PATH it mirrors) free of duplicates.
typeset -U path PATH

# Homebrew prefix: branch on the directory rather than shelling out to
# `brew --prefix`, which would fork a process on every shell start.
if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
else
  export HOMEBREW_PREFIX="/usr/local"
fi

# Order is highest-priority-first. The (N-/) glob qualifier drops entries whose
# directory doesn't exist (N: nullglob, -: follow symlinks, /: directories only)
# so PATH never accumulates dead paths.
#
# `mise activate` runs later in .zshrc and prepends its shims, so mise still
# wins for the runtimes it manages.
path=(
  $HOME/.local/bin(N-/)
  $HOMEBREW_PREFIX/bin(N-/)
  $HOMEBREW_PREFIX/sbin(N-/)
  $HOME/go/bin(N-/)
  /usr/local/go/bin(N-/)
  $path
)

export PATH
