# Launchd Module Context

## Purpose
macOS LaunchAgents for background automation. One agent: it shrinks oversized
screen recordings so they can be dropped straight into a Discord message.

## Key Files
| File | Description | Symlink Target |
|------|-------------|----------------|
| `Library/LaunchAgents/com.oinp.screenshots-compress.plist` | Fires `screenshots-compress` when `~/Pictures/Screenshots` changes | `~/Library/LaunchAgents/` |

## Dependencies
- `scripts/.local/bin/screenshots-compress` — the work; the agent only triggers it
- `ffmpeg` (with `libx265`) via Homebrew — already in the Brewfile
- **Vorssaint** produces the oversized `.mp4`. Its `recorderSaveFolder` must match
  `WatchPaths` in the plist (`~/Pictures/Screenshots`); the folder is declared in
  `scripts/.local/bin/vorssaint-apply`. Change one, change the other.

## Why this exists at all
Vorssaint's recorder cannot be configured down to a shareable size. It offers
coarse quality presets that scale *resolution*, never bitrate, and there is no
bitrate, CRF or codec setting to reach for. Its output lands at 4.7–9.8 Mbps —
a six-minute recording is 211 MB against Discord's 20 MB ceiling, a ~10x gap
that no preset in the app can express.

Worse, `recorderFrameRate` does not work. `vorssaint-apply` declares it 30 and
`defaults read com.vorssaint.utils` reads back 30, yet every file the editor
exports is 60fps. This is the same shape as the `outputScale` gap already noted
in `vorssaint-apply`: a declared setting that the export path ignores. Do not
spend time re-applying it — verify with `ffprobe`, not with `defaults read`.

This agent replaces `com.oinp.screenshots-to-mp4` (deleted in 46fb86e), which
watched for `.mov` and converted to `.mp4`. Vorssaint writes `.mp4` itself now,
so only the size problem is left.

## Why WatchPaths instead of fswatch
The deleted agent ran `KeepAlive` with a resident `fswatch` pipe. This one
declares `WatchPaths` and lets launchd's own kqueue watch fire the job, which:
- drops the `fswatch` Homebrew dependency — it is no longer installed
- has no resident process to leak, wedge or restart
- self-heals: a crashed run is simply not running, and the next file re-fires it

The cost is that launchd re-fires on *any* directory mutation, including the
sidecar the job itself writes. The script's eligibility rules must therefore
no-op on the second pass — see its header.

## Setup
```bash
stow -t ~ launchd
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.oinp.screenshots-compress.plist
```
`launchctl load` still works but is deprecated; `bootstrap`/`bootout` are the
supported spelling on modern macOS and give real error messages.

## Useful commands
```bash
# Is it registered, and what did it last exit with?
launchctl print gui/$(id -u)/com.oinp.screenshots-compress

# Run it right now without touching the folder
launchctl kickstart -k gui/$(id -u)/com.oinp.screenshots-compress

# Reload after editing the plist
launchctl bootout gui/$(id -u)/com.oinp.screenshots-compress
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.oinp.screenshots-compress.plist

# Logs
tail -f /tmp/screenshots-compress.log
tail -f /tmp/screenshots-compress.error.log
```

## Gotchas
- **launchd expands nothing.** No `~`, no `$HOME`, no variables in `WatchPaths`
  or `StandardOutPath`. Those two paths are absolute `/Users/oinp/...` out of
  necessity. `ProgramArguments` routes through `bash -c` specifically so that
  one can use `$HOME` and stay portable.
- **A plist in the repo is not a loaded agent.** Stowing puts the file in
  `~/Library/LaunchAgents/`; launchd does not read it until `bootstrap`, and
  will not pick up edits without `bootout` first. `scripts/checks.sh stow`
  catches an unstowed module but cannot tell you the agent is unloaded — check
  with `launchctl print`.
- **`Nice` and `LowPriorityIO` matter here.** An x265 encode saturates every
  core for minutes; without them, saving a recording makes the machine crawl.
