# fnox

Secret management, in two tiers:

- **Bitwarden vault = source of truth.** Backed up, cross-machine, visible in
  the desktop app. Where you add and rotate secrets.
- **macOS login keychain = local cache.** What every shell actually reads, at
  ~0.01s, with no prompt ever.

`secrets-pull` moves secrets from the first into the second. Nothing in this
repo ever contains a secret value.

## Symlink target
`~/.config/fnox/` → `fnox/.config/fnox/`

## Why this exists
Secrets used to sit in `zsh/.config/zsh/secrets.zsh` — plaintext, inside the git
working tree, kept out of history only by a `.gitignore` line. One `git add -f`,
one backup tool, or anything grepping `$HOME` would have had them.

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

## Why Bitwarden is not wired into the shell
It is tempting to point fnox straight at the vault and skip the cache. Don't.
Three measured reasons:

1. **`bw` costs ~1.2s per call** (it is a Node CLI). Shells resolve secrets on
   every new prompt, so this is paid constantly.
2. **`bw unlock` invalidates every other session.** Per `bw unlock --help`:
   *"After unlocking, any previous session keys will no longer be valid."* One
   agent unlocking silently breaks every other tab.
3. **Unattended processes cannot satisfy a master-password prompt.** An AI agent
   would either get an empty secret (silent auth failure downstream) or block on
   a GUI pinentry dialog.

The keychain has none of these properties: it unlocks at login and never
prompts. So Bitwarden is pulled from *explicitly*, by you, and the shell only
ever touches the keychain.

Storing `BW_SESSION` (or worse, the master password) somewhere to dodge the
prompt is a bad trade: that key decrypts your **entire vault**, a far larger
blast radius than the two scoped API tokens the keychain holds today.

## Usage
```bash
secrets-pull          # Bitwarden -> keychain (after rotating a secret)
secrets-pull -n       # dry run: report what would change, write nothing

fnox list             # what is defined (no values)
fnox get <KEY>        # print one value
fnox set -g <KEY>     # write straight to the keychain, bypassing the vault
fnox doctor           # diagnose resolution + provider health
fnox exec -- <cmd>    # run a command with secrets injected
```

To add a secret: create a Login item in Bitwarden named exactly after the env
var, put the value in its password field, add the pair to the `SECRETS` array in
`scripts/.local/bin/secrets-pull`, then run `secrets-pull`.

## Gotchas
- **`fnox sync` cannot do this.** It only accepts *encryption* providers (age,
  KMS) as targets and rejects the keychain: *"Provider 'keychain' cannot be used
  as a sync target."* Hence `secrets-pull` rather than a built-in.
- **`value` is the provider-side key name, and it is required.** Omit it and
  lookups fail *silently* — `fnox list` and `fnox doctor` still look healthy,
  but `get`/`export` return "not found" without ever querying the keychain.
  Always use `fnox set` rather than hand-editing this file.
- **`activate` is lazy.** It registers a `precmd`/`chpwd` hook instead of
  exporting at source time, so `zsh -i -c '...'` never sees the secrets (no
  prompt is drawn, so the hook never fires). Interactive shells are fine.
- **`fnox set` writes through symlinks**, so it edits the file in this repo
  directly. Expect `git status` to go dirty after `fnox set -g`.
- **Bitwarden item names must be unique** — `bw get` fails on ambiguous matches.
- **The cache can go stale.** Rotating a secret in Bitwarden does not reach the
  keychain until you run `secrets-pull`. This is deliberately not wired into
  `update.sh`, because it would make `dotup` block on a master-password prompt.
- Anything running as your user can read the keychain copies via
  `security find-generic-password` while the login keychain is unlocked. This
  protects secrets **at rest and from the repo**, not from local processes.

## Wiring
Activated in `zsh/.zshrc` (interactive-only, per the repo's external-eval rule).
Both secrets are ambient by design: the GitHub MCP server interpolates
`${GITHUB_PERSONAL_ACCESS_TOKEN}` from the environment when Claude Code starts.
To scope a secret to `fnox exec` only, add `env = "exec"` to its entry.

`FNOX_SHELL_OUTPUT=none` is exported there to silence the cosmetic
`fnox: +2 KEY1, KEY2` notice the hook prints on every new shell. It does **not**
suppress real diagnostics — a missing secret still logs `WARN ... not found`,
which is verified behaviour, not an assumption. Do not replace it with a blanket
`2>/dev/null` on the hook: that would hide those warnings too.

## On a new machine
`brew bundle` installs `fnox` and `bitwarden-cli`, and `stow` links this config,
but the keychain is empty — values do not travel with the repo. Until it is
populated, every shell prints a `WARN … not found` per missing secret (harmless,
but noisy).

```bash
bw config server https://vault.bitwarden.eu   # done by install.sh; EU account
bw login
secrets-pull
```

The EU server setting matters: `bw` defaults to the US server and otherwise
fails with a misleading *"Invalid master password"*.

Note that `fnox check` reports "healthy" even when values are missing — it
validates config structure, not resolution. Use `fnox get <KEY>` to prove a
secret actually resolves.
