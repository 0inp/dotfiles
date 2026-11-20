# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package whose contents are symlinked into `~` (home). Targets macOS on both **Apple Silicon** (`/opt/homebrew`) and **Intel** (`/usr/local`).

Each module has a `CONTEXT.md` with tool-specific details. `CONTEXT_MAP.md` at the root maps every module to its symlink target.

## Key Commands

**Stow (apply/remove symlinks):**

```bash
stow -t ~ [^.]*/      # symlink all packages (one package per module directory)
stow -t ~ <module>    # symlink a single module
stow -R -t ~ <module> # restow a module after adding/removing files in it
stow -D -t ~ [^.]*/   # remove all symlinks
```

Write `[^.]*/`, never `*/`: `.zshrc` sets `GLOBDOTS`, so in an interactive
shell `*/` also matches `.git/`, `.github/` and `.claude/`, and stow would
link the contents of `.git/` into `$HOME`.

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

Each module directory mirrors the target filesystem relative to `~`
(`zsh/.zshrc` → `~/.zshrc`). Files listed in a module's `.stow-local-ignore`
are not linked. Where to look:

- **Zsh**: `.zshenv` (all shells) → `.zprofile` (login) → `.zshrc`
  (interactive), which sources `~/.config/zsh/*.zsh`. File roles, atuin and
  the fzf/vi-mode binding order: `zsh/CONTEXT.md`.
- **PATH** is built in `zsh/.config/zsh/lib/path.zsh`, sourced from both
  `.zshenv` and `.zprofile` on purpose. Do not move it into
  `~/.config/zsh/*.zsh`: why is in `zsh/CONTEXT.md`.
- **Secrets**: never in the repo. Bitwarden is the source of truth,
  `secrets-pull` copies it to the macOS keychain, and fnox reads the keychain
  in every shell. `fnox/.config/fnox/config.toml` holds only references.
  Gotchas (silent lookups without `value`, lazy `activate`, no keychain
  `sync`) and why `bw` is not in shell startup: `fnox/CONTEXT.md`.
- **Runtimes**: mise pins Node, Python and Go, plus a global TypeScript 7 for
  Neovim's `tsc` LSP: `mise/CONTEXT.md`.
- **Git**: every commit and tag is signed with an SSH key: `git/CONTEXT.md`.

## Constraints

**Hooks are inert until `lefthook install` runs.** `lefthook.yml` is committed,
but `.git/hooks/` is never tracked — so a fresh clone has the config and zero
enforcement, looking fully protected the whole time. `scripts/install.sh` runs
it. Verify with `test -x .git/hooks/pre-commit`, not by reading `lefthook.yml`.
Same class of trap as a stow module that is committed, documented and never
stowed.

**The gitleaks Action's push job scans the pushed commits, not history.** It
stayed green for months while 47 findings sat in older commits; the weekly
`full-history` job is the audit. Both jobs share the workflow-level
`GITLEAKS_VERSION`, which `checks.sh ci` compares with the local binary.
Details in `.github/workflows/gitleaks.yml`.

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
