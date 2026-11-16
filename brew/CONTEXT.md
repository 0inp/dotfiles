# Brew Module Context

## Purpose
Configuration for Homebrew, the macOS package manager. Defines installed packages, taps, and casks.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `Brewfile`               | List of packages, taps, and casks    | `~/.config/brewfile/Brewfile`      |

There is no `~/.Brewfile`. Stow tree-folds the whole directory, so
`~/.config/brewfile` is a single symlink to `brew/.config/brewfile` and the
files inside it are not links of their own. `.zshenv` points
`HOMEBREW_BUNDLE_FILE_GLOBAL` at that path, which is what makes
`brew bundle --global` work from anywhere.

`Brewfile.lock.json` is **not** tracked — `brew/.gitignore` excludes it. It is a
machine-specific build artifact; the Brewfile is the source of truth.

## Containers (Colima)

Docker runs on [Colima](https://github.com/abiosoft/colima): headless, no app,
nothing mounted in Finder. OrbStack was dropped on 2026-11-16 for exactly that.
The `docker`, `docker-compose`, `docker-buildx` and `docker-credential-helper`
formulae replace the binaries OrbStack used to link into `/usr/local/bin`.

- **Runs only while used.** Not started at login. `docker`/`docker-compose` in
  `~/.local/bin` are shims (`scripts/.local/bin/colima-autostart`) that start
  the VM on first call (~20s), and `com.oinp.colima-idle-stop` stops it after
  two idle 15-min checks. That stands in for OrbStack's dynamic memory: an idle
  Colima VM measured ~1.1 GB of host RAM and keeps what Linux touched until
  stopped. A shim and not a zsh function because vicat-py resolves the socket
  with `docker context inspect` from bash, then Testcontainers connects to it.
  An IDE that opens the socket itself still needs `colima start` first.
- **VM settings** live in `~/.config/colima/default/colima.yaml`, not in this
  repo. The current VM was created with
  `colima start --cpu 4 --memory 6 --vm-type vz --vz-rosetta --mount-type virtiofs`;
  Rosetta is what lets `--platform linux/amd64` images run.
- **Only `~` is shared with the VM.** Bind-mounting a path under `/tmp` or
  `/private` gives the container an empty directory, silently.
- **`docker compose` needs `cliPluginsExtraDirs`** in `~/.docker/config.json`,
  which `scripts/install.sh` adds. Without it only `docker-compose` (dash) works.
- **The socket is `~/.config/colima/default/docker.sock`**, reached through the
  `colima` docker context. Tools that read `/var/run/docker.sock` directly need
  `DOCKER_HOST`; vicat's Testcontainers suites get it from vicat-py.

## Dependencies
- **Homebrew**: Install via `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`.

## Platform Notes
Homebrew installs to different paths depending on chip:
- **Apple Silicon**: `/opt/homebrew`
- **Intel**: `/usr/local`

The Brewfile itself is architecture-agnostic — Homebrew resolves the correct prefix at install time. However, any scripts or shell configs that reference Homebrew-installed package paths must use `$(brew --prefix <pkg>)` or branch on `[[ -d /opt/homebrew ]]`.

## Key Features
- **Packages**: CLI tools and applications (e.g., `eza`, `ripgrep`).
- **Taps**: Third-party repositories (e.g., `nikitabobko/aerospace`).
- **Casks**: GUI applications (e.g., `ghostty`, `stats`).

## AI Notes
- Focus on `Brewfile` for package management.
- Update lockfile with `brew bundle dump --force`.
- Test changes with `brew bundle check`.