# =========================================================
# Login shells
# =========================================================
# macOS's /etc/zprofile runs `path_helper`, which REBUILDS PATH from /etc/paths
# and /etc/paths.d with the system directories first — silently demoting
# everything ~/.zshenv set up. Because /etc/zprofile runs after .zshenv but
# before this file, re-asserting our PATH here is what keeps Homebrew ahead of
# /usr/local/bin (stale links left by Docker Desktop / OrbStack) in login shells.
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/lib/path.zsh"
