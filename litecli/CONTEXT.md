# LiteCLI Module Context

## Purpose
Configuration for [LiteCLI](https://litecli.com/), a command-line client for SQLite with auto-completion and syntax highlighting.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config`                 | LiteCLI keybindings, formatting, and behavior | `~/.config/litecli/config` |

## Dependencies
- **LiteCLI**: Install via Homebrew (`brew install litecli`).
- **SQLite**: Built into macOS or install via Homebrew (`brew install sqlite`).

## Key Features
- **Keybindings**: Custom shortcuts for query execution and navigation.
- **Formatting**: Syntax highlighting and output formatting.
- **History**: Command history and logging.

## AI Notes
- Focus on `config` for keybindings and formatting.
- Ignore `history` and `log` (user-specific, not configuration).
- Test changes by launching `litecli`.