# vicinae

[Vicinae](https://vicinae.com) is the launcher, on ⌘Space. It took that job over
from Vorssaint's command bar, which had taken it from Raycast. One tool, one job:
everything else Vicinae bundles (clipboard history, AI chat, dictation) is
switched off.

macOS support is **beta** (since v0.23) and Apple Silicon only. The cask
requires arm64 and macOS 14 or newer.

## Symlink target
`~/.config/vicinae/dotfiles.jsonc` → `vicinae/.config/vicinae/dotfiles.jsonc`
`~/.local/share/vicinae/scripts/` → `vicinae/.local/share/vicinae/scripts/`

## Why an import, not a stowed settings.json
Vicinae writes every change made in its GUI back into
`~/.config/vicinae/settings.json`: it reformats the file and drops comments.
Before 0.30.1 the atomic write (tmp + rename) also replaced a symlink with a
plain file; vicinae#2173 now writes through the link, but a stowed file would
still be rewritten inside the repo on every GUI change. So `settings.json`
stays a real, machine-local file, and the repo's settings live
in `dotfiles.jsonc`, pulled in by its `imports` array. Vicinae never writes
imported files.

Precedence is defaults < imports < `settings.json`. A value set in the GUI
therefore **wins** over `dotfiles.jsonc` until it is deleted from
`settings.json`. If a repo setting seems ignored, look there first.

On a fresh machine, after stowing, `settings.json` needs the import line:

```jsonc
{
  "$schema": "https://vicinae.com/schemas/config.json",
  "imports": ["./dotfiles.jsonc"]
}
```

Launch Vicinae once first: it creates `settings.json`.

## Settings that differ from the defaults
- `global_shortcuts.toggle = "control+space"`. That is ⌘Space: on macOS, Qt
  swaps Ctrl and Meta, so Vicinae's `control` is the Command key. The default is
  ⌥Space. Spotlight's own ⌘Space must stay disabled in System Settings ›
  Keyboard › Keyboard Shortcuts.
- `theme`: `one-dark`, chosen in the GUI over the bundled `catppuccin-mocha`.
  This is the one deliberate exception to the repo's Catppuccin Mocha. Themes
  ship in the app bundle (`Contents/Resources/themes/`).
- `tray.enabled = false` (no menu bar icon) and
  `launcher_window.compact_mode.enabled = true`, both chosen in the GUI.
- `telemetry.system_info = false`. It is on by default and posts system info at
  startup.
- `providers.{clipboard,ai,dictation}.enabled = false`, and `favorites = []` (the
  default pins `clipboard:history`). Disabling the clipboard provider only hides
  its commands: the clipboard server still starts and records. Recording is
  stopped by `providers.clipboard.preferences.monitoring = false`
  (`ClipboardPreferences` in the source), and `eraseOnStartup = true` empties
  what was captured before. The key shape comes from `ProviderData` in
  `src/server/src/config/config.hpp`. `vicinae cmd ls` keeps listing a disabled
  provider's commands, so it proves nothing. Check in the launcher itself.
- `providers.applications.entrypoints."com.etiennelescot.openscreen".shortcut =
  "control+shift+O"`: ⌘⇧O opens OpenScreen. The app registers that binding
  itself, but an Electron global shortcut only exists while the app runs, so it
  did nothing from a cold start.

## Script commands
Vicinae loads script commands from `~/.local/share/vicinae/scripts/`. This was
found by probing: the docs page for it returns a 404. The format is Raycast's,
with the `@vicinae.` prefix (`vicinae script template --title X`). After adding
a file, run `vicinae cmd launch core:reload-scripts`.

- `shots`, `desktop`, `downloads` open `~/Pictures/Screenshots`, `~/Desktop`
  and `~/Downloads` in Finder. `shots` is the quicklink that Raycast and then
  Vorssaint carried under the same name.
- `airmedia` runs `~/.local/bin/airmedia -d`: mounts the Air's media on
  `~/AirMedia` with rclone daemonized (the launcher cannot hold a foreground
  mount) and opens Finder. Eject in Finder to unmount.

## Useful commands
| Command | Does |
|---|---|
| `vicinae config default` | the full, commented default config, which is the real reference |
| `vicinae logs` | server logs; a config parse error shows here |
| `vicinae cmd ls` | every loaded entrypoint ID (for `favorites`, `fallbacks`, `providers`) |
| `vicinae toggle` | open or close the launcher |

## Constraint
`.gitignore` is an allowlist. On a machine without `~/.config/vicinae` or
`~/.local/share/vicinae`, stow tree-folds the directory into the repo, and
Vicinae's runtime files (`settings.json`, `vicinae.db`, `clipboard.db`) would
land here.
