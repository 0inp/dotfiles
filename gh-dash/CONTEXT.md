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

## Constraints

**`wt switch -x` takes a program, not a shell string** (worktrunk >= 0.76). The
`C` and `R` keybindings launch Claude in a PR worktree; the prompt must be a
separate argument after `--`:

```
wt switch pr:N -x claude -- "the prompt"     # correct
wt switch pr:N -x "claude \"the prompt\""     # pre-0.76; now fails with
                                             # "Failed to execute command
                                             #  (direct): No such file or
                                             #  directory (os error 2)"
```

Mind the three quoting layers: gh-dash renders the Go template, then the whole
command is a **single-quoted** shell word passed to `mux-new-window`, which
re-parses it with `bash -c`. So the prompt is wrapped in **plain** double quotes
— literal at the first parse, grouping at the second. `\"` would survive as a
literal `"` character and let the prompt split into one argument per word. `$BRANCH`
and `$BASE` expand at that second parse, which is where they are assigned.

## AI Notes
- Modify `config.yml` to change dashboard sections and filters
- Keybindings are defined in the config file for quick actions
- Test changes by running `gh dash`
