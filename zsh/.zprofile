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
# It APPENDS ~/.orbstack/bin, so it never outranks Homebrew. OrbStack's `docker`
# wins only because it is also linked into /usr/local/bin and the Brewfile has no
# docker formula: a brew `docker` would shadow it (29.9 client, 29.8 server).
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
