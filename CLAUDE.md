# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package whose contents are symlinked into `~` (home). Targets macOS on both **Apple Silicon** (`/opt/homebrew`) and **Intel** (`/usr/local`).

Each module has a `CONTEXT.md` with tool-specific details. `CONTEXT_MAP.md` at the root maps every module to its symlink target.

## Key Commands

**Stow (apply/remove symlinks):**
```bash
stow -t ~ .          # symlink all packages
stow -t ~ <module>   # symlink a single module
stow -D -t ~ .       # remove all symlinks
```

**Install (first time):**
```bash
./scripts/install.sh
```

**Update Homebrew packages:**
```bash
./scripts/update.sh
# or use the alias:
dotup
```

**Homebrew package management:**
```bash
brew bundle --file=./brew/.config/brewfile/Brewfile   # install all packages
brew bundle check --file=./brew/.config/brewfile/Brewfile  # verify installed
brew bundle dump --force --file=./brew/.config/brewfile/Brewfile  # regenerate lockfile
```

**Reload configs after changes:**
```bash
# Zsh: open a new shell or source directly
source ~/.zshrc

# Tmux: inside a tmux session
tmux source-file ~/.config/tmux/tmux.conf

# Herdr:
herdr server reload-config

# Aerospace:
aerospace reload-config

# Mise:
mise current   # verify active versions
```

**Update zsh plugins:**
```bash
zplugin-update   # defined in zsh/.config/zsh/plugins.zsh
```

## Architecture

### Stow layout
Each module directory mirrors the target filesystem structure relative to `~`. For example, `zsh/.zshrc` symlinks to `~/.zshrc` and `zsh/.config/zsh/aliases.zsh` symlinks to `~/.config/zsh/aliases.zsh`. Files listed in `.stow-local-ignore` inside a module are excluded from symlinking.

### Zsh configuration
`.zshenv` (all shells) → `.zprofile` (login shells) → `.zshrc` (interactive shells).
`.zshrc` sources all `~/.config/zsh/*.zsh` files at startup. Modules:
- `aliases.zsh` — shell aliases (tools: eza, bat, ripgrep, zoxide)
- `plugins.zsh` — self-managed plugins (auto-cloned with `_zplugin_load` on first run)
- `functions.zsh` — reusable shell functions (`rfv`, `timezsh`, `colormap`)
- `bindings.zsh` — vi-mode key bindings
- `fzf.zsh` — fzf configuration and keybindings
- `prompt.zsh` — prompt via `pure`
- `secrets.zsh` — not tracked in git (sensitive env vars)
- `lib/path.zsh` — PATH construction; in `lib/` so the `*.zsh` glob above skips it

Environment variables are set in `.zshenv` (loaded for all shells, including non-interactive).

**PATH is built in `zsh/.config/zsh/lib/path.zsh`**, which is sourced twice: from
`.zshenv` (so non-login, non-interactive shells get a usable PATH) and again from
`.zprofile`. The second pass is not redundant — macOS's `/etc/zprofile` runs
`path_helper`, which rebuilds PATH with the system directories first and would
otherwise demote Homebrew below `/usr/local/bin`. `typeset -U path` keeps the
re-assertion idempotent. Do not move this file to `~/.config/zsh/*.zsh`: `.zshrc`
globs that directory *after* `mise activate`, and re-running it there would hoist
Homebrew above the mise shims.

### Runtime versions (mise)
`mise/.config/mise/config.toml` pins global versions: Node 26, Python 3.14, Go 1.26. Mise is activated only in interactive shells.

### Git signing
All commits and tags are GPG-signed using an SSH key (`gpg.format = ssh`). The `gpg "ssh"` section points to `~/.ssh/allowed_signers`.

## Constraints

**Homebrew paths — never hardcode:** Always use `$(brew --prefix <pkg>)` in scripts. For performance-critical startup paths (`.zshenv`, `.zshrc`), use the branch pattern instead of spawning a subprocess:
```bash
if [[ -d /opt/homebrew ]]; then
  # Apple Silicon
else
  # Intel
fi
```

**Interactive-only guards:** Any zsh code that uses `zle`, `compinit`, or external evals (fzf, mise, zoxide, wt) must be wrapped in `[[ -o interactive ]]`. Sourcing these in non-interactive shells will break scripts and subshells.
