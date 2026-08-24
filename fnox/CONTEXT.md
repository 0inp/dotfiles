# fnox

Secret management. Secrets live in the **macOS login keychain**; this module
holds only the config that points at them.

## Symlink target
`~/.config/fnox/` → `fnox/.config/fnox/`

## Why this exists
Secrets used to sit in `zsh/.config/zsh/secrets.zsh` — plaintext, inside the git
working tree, kept out of history only by a `.gitignore` line. One `git add -f`,
one careless `stow`, one backup tool, or anything grepping `$HOME` would have
had them.

Now `config.toml` stores only *references*:

```toml
[providers.keychain]
type    = "keychain"
service = "fnox"

[secrets]
GITHUB_PERSONAL_ACCESS_TOKEN= { provider = "keychain", value = "GITHUB_PERSONAL_ACCESS_TOKEN" }
```

The values are in `login.keychain-db`. That is why this file is committed while
`secrets.zsh` never could be.

## Usage
```bash
fnox list             # what is defined (no values)
fnox get <KEY>        # print one value
fnox set -g <KEY>     # store/update; reads stdin or prompts, never argv
fnox doctor           # diagnose resolution + provider health
fnox exec -- <cmd>    # run a command with secrets injected
```

`-g` targets this global config. Without it, `fnox` looks for a `fnox.toml` in
the current directory and its parents — that is the per-project mode.

## Gotchas
- **`value` is the provider-side key name, and it is required.** Omit it and
  lookups fail *silently* — `fnox list` and `fnox doctor` still look healthy,
  but `get`/`export` return "not found" without ever querying the keychain.
  Always use `fnox set` rather than hand-editing this file.
- **`activate` is lazy.** It registers a `precmd`/`chpwd` hook instead of
  exporting at source time, so `zsh -i -c '...'` never sees the secrets (no
  prompt is drawn, so the hook never fires). Interactive shells are fine.
- **`fnox set` writes through symlinks**, so it edits the file in this repo
  directly. Expect `git status` to go dirty after `fnox set -g`.
- Anything running as your user can read these via `security find-generic-password`
  while the login keychain is unlocked. This protects secrets **at rest and from
  the repo**, not from local processes.

## Wiring
Activated in `zsh/.zshrc` (interactive-only, per the repo's external-eval rule).
Both secrets are ambient by design: the GitHub MCP server interpolates
`${GITHUB_PERSONAL_ACCESS_TOKEN}` from the environment when Claude Code starts.
To scope a secret to `fnox exec` only, add `env = "exec"` to its entry.

## On a new machine
`brew bundle` installs fnox and `stow` links this config, but the keychain is
empty — the values do not travel with the repo. Until you populate them, every
shell prints a `WARN … not found` per missing secret (harmless, but noisy):

```bash
fnox set -g GITHUB_PERSONAL_ACCESS_TOKEN   # prompts, hidden input
fnox set -g LINEAR_API_KEY
```

Note that `fnox check` reports "healthy" even when values are missing — it
validates config structure, not resolution. Use `fnox get <KEY>` to prove a
secret actually resolves.
