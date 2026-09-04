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

**A section title is not its scope — `smartFilteringAtLaunch` is.** It
defaults to `true`, so launching `gh dash` in a repo prepends
`repo:<owner>/<name>` to *every* section: from `~/dev/sillant/Table`, tab 1
runs `is:pr repo:Sillant/Table is:open author:@me`. The `All PRs` tab therefore
means "all PRs of the current repo" there, and only widens to `org:Sillant`
when gh dash is launched outside a clone. Kept on deliberately — repo focus is
the common case. Read the query box at the top before trusting a count.

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

**Never clean up the `C` worktree with `--force`.** `/pr-comments` is gated: it
applies the review fixes locally and then *stops*, waiting for an explicit GO
before committing. Quitting Claude at that gate leaves real work uncommitted in
the worktree — and `wt remove --force` deletes a dirty worktree, "including
staged, modified, and untracked files", silently. Without `--force`, wt refuses
(exit 1, message on **stderr**) and the work survives, so the cleanup is a plain
`if`; the old form also piped stderr to `/dev/null` and then printed its success
line unconditionally, which reported a removal that never happened.

`wt switch pr:N` **reuses** an existing worktree for that branch rather than
creating one, so on your own PR the cleanup would remove the worktree you were
working in — with the ignored files the `post-start` `copy-ignored` hook had
to fetch. Hence the `PRE` probe: `git worktree list` is read *before* the
switch, and a worktree that already existed is left alone. Ignored files alone
do not make a worktree dirty (verified) — only tracked-file changes and
untracked files do.

## AI Notes
- Modify `config.yml` to change dashboard sections and filters
- Keybindings are defined in the config file for quick actions
- Test changes by running `gh dash`
