# Zsh Module Context

## Purpose
Configuration for Zsh, the default shell on macOS.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.zshrc`                 | Zsh startup script                   | `~/.zshrc`                         |
| `.zshenv`                | Environment variables                | `~/.zshenv`                        |
| `aliases.zsh`            | Shell aliases                        | `~/.config/zsh/aliases.zsh`        |
| `bindings.zsh`           | Keybindings                          | `~/.config/zsh/bindings.zsh`       |
| `functions.zsh`          | Custom shell functions               | `~/.config/zsh/functions.zsh`      |
| `fzf.zsh`                | FZF integration                      | `~/.config/zsh/fzf.zsh`            |
| `plugins.zsh`            | Plugin management                    | `~/.config/zsh/plugins.zsh`        |
| `prompt.zsh`             | Prompt customization                 | `~/.config/zsh/prompt.zsh`         |
| `secrets.zsh`            | Sensitive environment variables      | `~/.config/zsh/secrets.zsh`        |

## Dependencies
- **Zsh**: Pre-installed on macOS or install via Homebrew (`brew install zsh`).
- **Plugins**: Self-managed — cloned on first load by `plugins.zsh` into `$ZPLUGINDIR`.

## Platform Notes
Supports **Apple Silicon** (`/opt/homebrew`) and **Intel** (`/usr/local`). Architecture-sensitive paths in `.zshenv` and `.zshrc`:
- `sbin` PATH entry already branches on `[[ -d /opt/homebrew/sbin ]]`.
- Any new references to Homebrew-installed tools must use `$(brew --prefix <pkg>)` or the same `[[ -d /opt/homebrew ]]` pattern — never hardcode `/opt/homebrew` alone.

## Key Features
- **Aliases**: Shortcuts for common commands.
- **Keybindings**: Custom keyboard shortcuts.
- **Functions**: Reusable shell utilities.
- **FZF**: Fuzzy-finder integration.
- **Plugins**: Extensions for productivity.
- **Prompt**: Custom shell prompt.

## AI Notes
- Focus on `.zshrc` for startup configuration.
- Use `aliases.zsh` and `functions.zsh` for reusable logic.
- Test changes by launching a new shell (`zsh`).