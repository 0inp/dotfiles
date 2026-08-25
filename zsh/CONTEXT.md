# Zsh Module Context

## Purpose
Configuration for Zsh, the default shell on macOS.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.zshrc`                 | Zsh startup script                   | `~/.zshrc`                         |
| `.zshenv`                | Environment variables                | `~/.zshenv`                        |
| `.zprofile`              | Login shells; re-sources `path.zsh`  | `~/.zprofile`                      |
| `aliases.zsh`            | Shell aliases                        | `~/.config/zsh/aliases.zsh`        |
| `bindings.zsh`           | Keybindings                          | `~/.config/zsh/bindings.zsh`       |
| `functions.zsh`          | Custom shell functions               | `~/.config/zsh/functions.zsh`      |
| `fzf.zsh`                | FZF integration                      | `~/.config/zsh/fzf.zsh`            |
| `plugins.zsh`            | Plugin management                    | `~/.config/zsh/plugins.zsh`        |
| `prompt.zsh`             | Prompt customization                 | `~/.config/zsh/prompt.zsh`         |
| `lib/path.zsh`           | PATH construction (skipped by glob)  | `~/.config/zsh/lib/path.zsh`       |

## Dependencies
- **Zsh**: Pre-installed on macOS or install via Homebrew (`brew install zsh`).
- **Plugins**: Self-managed — cloned on first load by `plugins.zsh` into `$ZPLUGINDIR`.

## Platform Notes
Supports **Apple Silicon** (`/opt/homebrew`) and **Intel** (`/usr/local`).
- PATH is built in `lib/path.zsh`, which sets `HOMEBREW_PREFIX` by branching on
  `[[ -d /opt/homebrew ]]` rather than forking `brew --prefix` on every shell.
  Entries use the `(N-/)` glob qualifier so non-existent dirs are dropped.
- Any new references to Homebrew-installed tools must use `$(brew --prefix <pkg>)` or the same `[[ -d /opt/homebrew ]]` pattern — never hardcode `/opt/homebrew` alone.

## Key Features
- **Aliases**: Shortcuts for common commands.
- **Keybindings**: Custom keyboard shortcuts.
- **Functions**: Reusable shell utilities.
- **FZF**: Fuzzy-finder integration.
- **Plugins**: Extensions for productivity.
- **Prompt**: Custom shell prompt (`pure`).
- **History**: `atuin` provides SQLite-backed history and fuzzy Ctrl-R.
  Up/Down stay on `zsh-history-substring-search` (`--disable-up-arrow`), and
  atuin's `?` AI binding is off (`--disable-ai`) because `?` is a vi motion.
- **Secrets**: resolved from the macOS keychain by `fnox` (see the `fnox` module); there is no `secrets.zsh` any more.

## Keybinding gotcha
zsh-vi-mode rebuilds the viins/vicmd keymaps at init, wiping any `bindkey` made
before that. Bindings that must survive go in **`zvm_after_init_commands`** —
**lowercase**. The uppercase `ZVM_AFTER_INIT_COMMANDS` is not read by the plugin
at all and fails silently. (The `ZVM_*_MODE_CURSOR` and `ZVM_VI_HIGHLIGHT_*`
settings *are* uppercase; only the command arrays are lowercase.)

## AI Notes
- Focus on `.zshrc` for startup configuration.
- Use `aliases.zsh` and `functions.zsh` for reusable logic.
- Test changes by launching a new shell (`zsh`). Keybindings in particular
  cannot be verified with `zsh -i -c ...`: that never draws a prompt, so
  zsh-vi-mode's deferred init never runs. Use a real pty and assert on
  `bindkey '<key>'` output.