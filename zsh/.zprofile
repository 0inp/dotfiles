# =========================================================
# Login shells
# =========================================================
# macOS's /etc/zprofile runs `path_helper`, which REBUILDS PATH from /etc/paths
# and /etc/paths.d with the system directories first — silently demoting
# everything ~/.zshenv set up. Because /etc/zprofile runs after .zshenv but
# before this file, re-asserting our PATH here is what keeps Homebrew ahead of
# /usr/local/bin (Docker Desktop, OrbStack) in login shells.
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/lib/path.zsh"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
# Kept AFTER the PATH block on purpose, so OrbStack's own bin dir keeps the
# precedence its installer intended (its `docker`/`orb` shims win over Homebrew).
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
