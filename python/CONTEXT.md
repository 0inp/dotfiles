# Python Module Context

## Purpose
Configuration for Python environments and REPL behavior.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `.python-version`        | Default Python version (for `mise`)  | `~/.python-version`                |
| `.pythonrc`              | Python REPL startup script           | `~/.pythonrc`                      |

## Dependencies
- **Python**: Managed via Mise (`mise install python`).

## Key Features
- **Version Management**: Default Python version for projects.
- **REPL Customization**: Auto-imports, aliases, and startup commands.

## AI Notes
- Focus on `.pythonrc` for REPL customizations.
- Use `.python-version` to set the default Python version.
- Test changes by launching `python` or `ipython`.