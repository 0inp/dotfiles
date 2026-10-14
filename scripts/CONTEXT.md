# Scripts Module Context

## Purpose
Custom scripts for dotfiles management and system automation.

## Key Files
`.stow-local-ignore` excludes `*.sh` and `CONTEXT.md`, so the top-level scripts
are **not** symlinked — they are run from the repo. Only `.local/bin/` is stowed.

| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `install.sh`             | Bootstrap a fresh machine            | *(not stowed; run from repo)*      |
| `update.sh`              | Update brew/mise/plugins/extensions  | *(not stowed; run from repo)*      |
| `changelog.sh`           | Changelog digest sourced by `update.sh` | *(not stowed; sourced, not run)* |
| `checks.sh`              | Repo invariants run by lefthook pre-push | *(not stowed; run from repo)*     |
| `.local/bin/secrets-pull`| Bitwarden vault -> macOS keychain    | `~/.local/bin/secrets-pull`        |
| `.local/bin/mux-new-window`| Open a window in herdr             | `~/.local/bin/mux-new-window`      |
| `.local/bin/vorssaint-apply`| Declared Vorssaint settings -> UserDefaults | `~/.local/bin/vorssaint-apply` |
| `.local/bin/captures-tidy`| Rename captures, shrink recordings under 20 MB | `~/.local/bin/captures-tidy` |

## Dependencies
- **Shell**: Requires `zsh` or `bash`.
- **Stow**: Install via Homebrew (`brew install stow`).

## Platform Notes
`install.sh` targets **macOS on both Apple Silicon and Intel**. The script already checks `uname` for macOS. When adding new setup steps that reference Homebrew paths, branch on `[[ -d /opt/homebrew ]]` (Apple Silicon) vs `/usr/local` (Intel) rather than hardcoding either.

## Key Features
- **Installation**: Automates dotfiles symlinking and dependency setup.
- **Updates**: Orchestrates system updates (Homebrew, macOS, etc.).
- **Secrets**: `secrets-pull` refreshes the keychain from the Bitwarden vault (see the `fnox` module).
- **Changelog digest**: `update.sh` ends with a digest of what actually changed,
  implemented in `changelog.sh`. A changelog is a *delta*, and the update steps
  destroy its "before" half as they run — once brew has upgraded, `brew outdated`
  is empty and every plugin repo has fast-forwarded. So it comes in two halves:
  `cl_snapshot` runs before any upgrade, `cl_report` diffs against it at the end.
  Adding a new update step means adding its "before" capture to `cl_snapshot`.

  Changelog coverage differs sharply by source, and that is inherent, not a bug:

  | Source         | Notes quality | How they are resolved                       |
  |----------------|---------------|---------------------------------------------|
  | Zsh plugins    | **Exact**     | Git checkouts — `git log old..new`, no network |
  | gh extensions  | **Exact**     | Repo and tag come straight from `gh extension list` |
  | mise tools     | Good          | `mise registry` gives `aqua:owner/repo`     |
  | brew formulae  | ~75%          | Regex `github.com/owner/repo` out of the source URL, then the homepage |
  | brew casks     | Poor          | Mostly closed-source apps with no public notes |

  Three constraints worth knowing before editing it:
  - **bash 3.2.** `#!/bin/bash` on macOS is the 2007 build, so no associative
    arrays, no `mapfile`, and no bare `"${arr[@]}"` on a possibly-empty array
    under the `set -u` that `update.sh` enables.
  - **`golang/go` and `python/cpython` publish zero GitHub releases** (tags only,
    verified against the API), so those two can never resolve through the releases
    endpoint. `_cl_mise_docs` maps them to their real release-notes pages instead.
  - **It may never break the run.** `update.sh` omits `set -e` on purpose; every
    function here returns 0 and every failed lookup degrades to a bare
    `old → new` line. Missing `jq` or `gh` costs sections, not the digest.
- **Repo invariants**: `checks.sh` holds the tests lefthook runs before a push.
  They are not linters — each encodes a way this repo has actually broken, so
  the failure message names the fix. Run any subset by hand:
  `bash scripts/checks.sh symlinks`, or `all` for everything. Exit status is
  the number of failed checks.

  | Check      | Catches                                                    |
  |------------|------------------------------------------------------------|
  | `secrets`  | gitleaks over the commits about to be pushed                |
  | `stow`     | a module committed and documented but never stowed          |
  | `symlinks` | a relative skill link with the wrong `..` depth             |
  | `zvm`      | the uppercase `ZVM_AFTER_INIT_COMMANDS`, which nothing reads |
  | `fnox`     | a literal value where a keychain reference belongs          |
  | `brewfile` | installed packages drifting from the manifest               |

  Two constraints worth knowing before editing it:
  - **`symlinks` reads the git index, not the working tree.** It resolves each
    link relative to its path *in the repo*, which is where the kernel
    resolves it once stow tree-folds the parent. Fixing a link in the working
    tree without staging it leaves the check red, correctly.
  - **`secrets` scans the push range, not history.** A full-history scan is
    ~95s here. Nothing currently audits full history — see the note in
    `checks.sh`; the GitHub Action scans the last commit only.

- **Vorssaint**: `vorssaint-apply` is this repo's Vorssaint config. The app has
  no config file — every setting is UserDefaults in `com.vorssaint.utils` — so
  the settings are *declared* in that script and pushed with `defaults write`.
  It quits Vorssaint first: cfprefsd would otherwise flush the running app's
  cached preferences over the writes. Run it **after** the first launch, which
  is what grants Screen Recording and Accessibility. `-n` dry-runs.

## AI Notes
- Focus on `install.sh` for dotfiles setup.
- Use `update.sh` for system maintenance.
- Test changes by running scripts locally.