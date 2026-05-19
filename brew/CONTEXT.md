# Brew Module Context

## Purpose
Configuration for Homebrew, the macOS package manager. Defines installed packages, taps, and casks.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `Brewfile`               | List of packages, taps, and casks    | `~/.Brewfile`                      |
| `Brewfile.lock.json`     | Lockfile for reproducible installs   | `~/.Brewfile.lock.json`            |

## Dependencies
- **Homebrew**: Install via `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`.

## Key Features
- **Packages**: CLI tools and applications (e.g., `eza`, `ripgrep`).
- **Taps**: Third-party repositories (e.g., `nikitabobko/aerospace`).
- **Casks**: GUI applications (e.g., `ghostty`, `stats`).

## AI Notes
- Focus on `Brewfile` for package management.
- Update lockfile with `brew bundle dump --force`.
- Test changes with `brew bundle check`.