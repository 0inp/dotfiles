# Colima Module Context

## Purpose
Docker on this Mac runs in a [Colima](https://github.com/abiosoft/colima) VM.
This module holds the one file Colima's own config can't express: Lima's
global override, which keeps forwarded ports off the LAN.

## Key Files
| File | Description | Symlink Target |
|------|-------------|----------------|
| `.config/colima/_lima/_config/override.yaml` | Lima port-forward rules, tried before Colima's | `~/.config/colima/_lima/_config/override.yaml` |

**Stow must not fold `~/.config/colima`.** It is Colima's state directory (VM
disks, sockets, `colima.yaml`). On a machine where it doesn't exist yet, stow
would make it a single link into this repo and the VM would be written here.
`scripts/install.sh` creates `~/.config/colima/_lima/_config` before stowing
so only the file is linked. The same holds for any manual first stow.

## Ports stay on loopback
Colima forwards every port a container publishes on `0.0.0.0` to `0.0.0.0` on
the Mac, and has no flag to change it (`colima start --help`). With the macOS
firewall off, `docker run -p 18080:80` answered on `192.168.18.18:18080` from
the LAN. The hostagent also forwarded the VM's internal dnsmasq to `*:53`.
`override.yaml` ignores port 53 and pins `0.0.0.0` forwards to `127.0.0.1`.
Lima tries override rules first and the first match wins. Verified on
2026-11-16: LAN refused, localhost 200, container DNS still resolves.

To expose one service on the LAN on purpose, there is no per-port escape
hatch here; remove the rule, `colima stop && colima start`, and put it back.

Changes take effect on `colima stop && colima start` only.

## Setup


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
  `colima` docker context. `.zshenv` also exports it as `DOCKER_HOST`, plus
  `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE`, for Testcontainers (it ignores
  contexts, and Ryuk must mount the VM-side socket). So `docker context show`
  prints `default`; that is expected. Verified with a Postgres container and
  Ryuk from vicat's price_bible venv.
