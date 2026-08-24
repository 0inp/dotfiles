# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package whose contents are symlinked into `~` (home). Targets macOS on both **Apple Silicon** (`/opt/homebrew`) and **Intel** (`/usr/local`).

Each module has a `CONTEXT.md` with tool-specific details. `CONTEXT_MAP.md` at the root maps every module to its symlink target.

## Key Commands

**Stow (apply/remove symlinks):**
```bash
stow -t ~ */          # symlink all packages (one package per module directory)
stow -t ~ <module>    # symlink a single module
stow -R -t ~ <module> # restow a module after adding/removing files in it
stow -D -t ~ */       # remove all symlinks
```

Never use `stow -t ~ .`. That names the repo root itself as a single package,
which symlinks `aerospace/`, `brew/`, `CLAUDE.md`, `.github/` and friends
straight into `$HOME`, and bypasses every `.stow-local-ignore`.

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

`HOMEBREW_BUNDLE_FILE_GLOBAL` (set in `.zshenv`) points at this repo's Brewfile,
so `--global` works from anywhere. It's the `_GLOBAL` variant on purpose — plain
`HOMEBREW_BUNDLE_FILE` would hijack a project's own `./Brewfile`.

```bash
brew bundle --global               # install all packages
brew bundle check --global         # verify installed
brew bundle dump --force --global  # regenerate the Brewfile
```

`Brewfile.lock.json` is gitignored: it's a machine-specific build artifact, and
the Brewfile is the source of truth.

**Reload configs after changes:**
```bash
# Zsh: open a new shell or source directly
source ~/.zshrc

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
- `aliases.zsh` — shell aliases (tools: eza, bat, zoxide). Note: `grep` is **not**
  aliased to `rg`; rg's defaults live in the `ripgrep` module instead.
- `plugins.zsh` — self-managed plugins (auto-cloned with `_zplugin_load` on first run)
- `functions.zsh` — reusable shell functions (`rfv`, `timezsh`, `colormap`)
- `bindings.zsh` — vi-mode key bindings
- `fzf.zsh` — fzf configuration and keybindings
- `prompt.zsh` — prompt via `pure`
- `lib/path.zsh` — PATH construction; in `lib/` so the `*.zsh` glob above skips it

Environment variables are set in `.zshenv` (loaded for all shells, including non-interactive).

### Secrets (fnox + Bitwarden)
Secrets are **not** stored in the repo. Two tiers:

- **Bitwarden vault** — source of truth. Where you add and rotate secrets.
- **macOS login keychain** — local cache, read by every shell via
  [fnox](https://fnox.jdx.dev/) (activated from `.zshrc`).

`scripts/.local/bin/secrets-pull` moves vault → keychain.
`fnox/.config/fnox/config.toml` is committed on purpose: it holds only
*references* (`{ provider = "keychain", value = "KEY_NAME" }`), never values.

```bash
secrets-pull               # refresh keychain from the vault (-n for dry run)
fnox list                  # what is defined
fnox get <KEY>             # print one value
fnox doctor                # diagnose resolution
```

Bitwarden is deliberately **not** wired into shell startup: `bw` costs ~1.2s per
call, and per `bw unlock --help` *"after unlocking, any previous session keys
will no longer be valid"* — so one agent unlocking would break every other tab.
Unattended agents also cannot answer a master-password prompt. See
`fnox/CONTEXT.md` for the full reasoning.

Three gotchas:
- The `value` field is the **provider-side key name**. Omit it and lookups fail
  *silently* (a warning, not an error). Prefer `fnox set` over hand-editing.
- `activate` registers a `precmd` hook rather than exporting eagerly, so
  `zsh -i -c '...'` (which never draws a prompt) will not see the secrets.
  Real interactive shells are unaffected.
- `fnox sync` cannot target the keychain (encryption providers only), which is
  why `secrets-pull` exists instead.

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
