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
| `.local/bin/secrets-pull`| Bitwarden vault -> macOS keychain    | `~/.local/bin/secrets-pull`        |
| `.local/bin/mux-new-window`| Open a window in herdr             | `~/.local/bin/mux-new-window`      |

## Dependencies
- **Shell**: Requires `zsh` or `bash`.
- **Stow**: Install via Homebrew (`brew install stow`).

## Platform Notes
`install.sh` targets **macOS on both Apple Silicon and Intel**. The script already checks `uname` for macOS. When adding new setup steps that reference Homebrew paths, branch on `[[ -d /opt/homebrew ]]` (Apple Silicon) vs `/usr/local` (Intel) rather than hardcoding either.

## Key Features
- **Installation**: Automates dotfiles symlinking and dependency setup.
- **Updates**: Orchestrates system updates (Homebrew, macOS, etc.).
- **Secrets**: `secrets-pull` refreshes the keychain from the Bitwarden vault (see the `fnox` module).

## AI Notes
- Focus on `install.sh` for dotfiles setup.
- Use `update.sh` for system maintenance.
- Test changes by running scripts locally.