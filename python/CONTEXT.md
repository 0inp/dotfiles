# Python Module Context

## Purpose
Configuration for Python environments and REPL behavior.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.pythonrc`              | Python REPL startup script           | `~/.pythonrc`                      |

This module contains **only** `.pythonrc`. It previously documented a
`.python-version` file that has never existed here — the Python version is
pinned globally in `mise/.config/mise/config.toml` instead. A dead
`.config/pypoertry/` directory (typo for `pypoetry`) was also removed: Poetry
is not installed, `uv` is the package manager.

## Dependencies
- **Python**: Managed via Mise (`mise install python`).

## Key Features
- **REPL Customization**: Auto-imports, aliases, and startup commands, loaded
  via `PYTHONSTARTUP` (set in `.zshenv`).

## AI Notes
- Focus on `.pythonrc` for REPL customizations.
- To change the Python version, edit `mise/.config/mise/config.toml`.
- Test changes by launching `python` or `ipython`.