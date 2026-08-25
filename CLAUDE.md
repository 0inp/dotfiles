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

**Git hooks (lefthook):**
```bash
lefthook install                # write .git/hooks (idempotent; install.sh runs it)
lefthook run pre-commit         # run the fast, staged-file checks by hand
lefthook run pre-push --force   # run the whole-repo checks with nothing to push
bash scripts/checks.sh all      # just the repo invariants, no lefthook
LEFTHOOK=0 git commit ...       # bypass for one command
```
`lefthook.yml` at the repo root is the config. pre-commit sees only staged
files (gitleaks, syntax, shellcheck, then shfmt/stylua which auto-restage);
pre-push runs the whole-repo invariants in `scripts/checks.sh`.

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
- `bindings.zsh` — vi-mode key bindings, plus the `zvm_after_init_commands`
  entries that re-apply bindings zsh-vi-mode would otherwise wipe
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
`mise/.config/mise/config.toml` pins global versions: Node 26, Python 3.14,
Go 1.26. Mise is activated only in interactive shells.

It also carries `"npm:typescript" = "7"`. That is not a runtime pin — Neovim's
`tsc` language server needs a TypeScript 7 binary on `$PATH` as a fallback for
repos still on TS 5/6, and Mason has no `typescript` package. See
`nvim/CONTEXT.md`.

### Shell history (atuin)
`atuin` replaces Ctrl-R with fuzzy search over a SQLite history that records
cwd, exit code and duration. Initialised interactive-only in `.zshrc` with
`--disable-up-arrow` (Up/Down stay on zsh-history-substring-search) and
`--disable-ai` (it would otherwise bind `?`, a vi motion). Its bindings are
re-applied from `zvm_after_init_commands` — see the constraint below.

### Git signing
All commits and tags are GPG-signed using an SSH key (`gpg.format = ssh`). The `gpg "ssh"` section points to `~/.ssh/allowed_signers`.

## Constraints

**Hooks are inert until `lefthook install` runs.** `lefthook.yml` is committed,
but `.git/hooks/` is never tracked — so a fresh clone has the config and zero
enforcement, looking fully protected the whole time. `scripts/install.sh` runs
it. Verify with `test -x .git/hooks/pre-commit`, not by reading `lefthook.yml`.
Same class of trap as a stow module that is committed, documented and never
stowed.

**The gitleaks Action's push job scans one commit, not history.**
gitleaks-action invokes gitleaks with `--log-opts=-1` — the last commit only —
so `fetch-depth: 0` buys nothing there. It stayed green in ~10s for months
while 47 findings, including real credentials from 2020 and 2022, sat in
older history. The separate weekly `full-history` job exists because of that,
and runs the gitleaks binary directly rather than the action, whose scan
scope varies by event type and is undocumented.

**`.gitleaks.toml` is triage, not suppression.** Every allowlist entry records
a finding that was looked at and accepted — GPG signing-key fingerprints are
public identifiers, and the legacy `symlinks/` tree holds vendored Raycast
bundles plus two knowingly-accepted packagecloud tokens that have been public
since 2020. It also makes the full scan fast: skipping those vendored bundles
takes a whole-history scan from ~95s to ~0.6s. One config serves the hooks and
both CI jobs, so a finding cannot be green locally and red in CI.

**Homebrew paths — never hardcode:** Always use `$(brew --prefix <pkg>)` in scripts. For performance-critical startup paths (`.zshenv`, `.zshrc`), use the branch pattern instead of spawning a subprocess:
```bash
if [[ -d /opt/homebrew ]]; then
  # Apple Silicon
else
  # Intel
fi
```

**zsh-vi-mode keybindings — the array name is lowercase:** any `bindkey` that
must outlive zsh-vi-mode's keymap rebuild goes in **`zvm_after_init_commands`**.
The uppercase `ZVM_AFTER_INIT_COMMANDS` is read by nothing and fails silently;
three bindings (`^g`→rfv, Up/Down→history-substring-search) were dead this way.
The `ZVM_*_MODE_CURSOR` / `ZVM_VI_HIGHLIGHT_*` settings *are* uppercase — only
the command arrays are lowercase.

**Verify keybindings in a real pty.** `zsh -i -c '...'` never draws a prompt, so
zsh-vi-mode's deferred init never runs and every `zvm_after_init_commands` entry
appears broken (or, worse, appears fine). Same trap as the `fnox activate`
precmd hook. Drive a real `pty.fork()` and assert on `bindkey '<key>'` output.

**Check the symlink before debugging the syntax.** A module can be committed,
documented in `CONTEXT.md` and listed in `CONTEXT_MAP.md` while never being
stowed — `worktrunk` was inert for months this way. `stow -n -v -t ~ <module>`
prints a `LINK:` line for anything not yet linked; no output means it is stowed.

**Relative symlinks inside `~/.claude` resolve from the repo, not from `~`.**
Stow tree-folds `~/.claude` into a single link to `dotfiles/claude/.claude`, so the
kernel resolves anything under it against the *physical* path. Every skill in
`claude/.claude/skills/` pointed at `../../.agents/skills/<name>` — correct if
`~/.claude` were a real directory, but it lands on
`dotfiles/claude/.agents/skills/<name>`, which does not exist. All 42 personal
skills were invisible to Claude Code this way, and the sessions that asked for one
silently fell back to a plugin skill. Count the `..` from
`dotfiles/claude/.claude/skills/`, not from `~/.claude/skills/`: the correct target
is `../../../agents/.agents/skills/<name>`, which also keeps the link inside the
repo. Verify with `test -e ~/.claude/skills/<name>/SKILL.md`, never with
`readlink` — a broken link still prints a plausible target.

**Interactive-only guards:** Any zsh code that uses `zle`, `compinit`, or external evals (fzf, mise, zoxide, wt) must be wrapped in `[[ -o interactive ]]`. Sourcing these in non-interactive shells will break scripts and subshells.
