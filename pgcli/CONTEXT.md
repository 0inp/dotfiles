# PgCLI Module Context

## Purpose
Configuration for [PgCLI](https://www.pgcli.com/), a command-line client for PostgreSQL with auto-completion and syntax highlighting.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config`                 | PgCLI keybindings, formatting, and behavior | `~/.config/pgcli/config` |

## Dependencies
- **PgCLI**: Install via Homebrew (`brew install pgcli`).
- **PostgreSQL**: Install via Homebrew (`brew install postgresql`).

## Key Features
- **Keybindings**: Custom shortcuts for query execution and navigation.
- **Formatting**: Syntax highlighting and output formatting.
- **History**: Command history and logging.

## AI Notes
- Focus on `config` for keybindings and formatting.
- Ignore `history` (user-specific, not configuration).
- Test changes by launching `pgcli`.