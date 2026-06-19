# GitHub Dash Module Context

## Purpose
Configuration for [gh-dash](https://github.com/dlvhdr/gh-dash), a GitHub CLI extension for displaying PRs, issues, and notifications in a dashboard.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config.yml`             | Dashboard layout and filter config    | `~/.config/gh-dash/config.yml`     |

## Dependencies
- **gh-dash**: Install via Homebrew (`brew install dlvhdr/tap/gh-dash`)
- **GitHub CLI**: Required (`brew install gh`)

## Key Features
- **PR Dashboard**: View and manage pull requests
- **Issue Dashboard**: Track issues across repositories
- **Notifications**: Monitor GitHub notifications
- **Custom Keybindings**: Quick actions for common tasks

## AI Notes
- Modify `config.yml` to change dashboard sections and filters
- Keybindings are defined in the config file for quick actions
- Test changes by running `gh dash`
