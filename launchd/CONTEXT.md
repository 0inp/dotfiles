# Launchd Module Context

## Purpose
macOS LaunchAgents for background automation. One agent, `captures-tidy`, which
does two things to `~/Pictures/Screenshots` whenever it changes:

1. **renames** every capture to `SS_YYYY_MM_DD_-_hh_mm_ss` (screenshots) or
   `SR_...` (recordings), so the folder sorts chronologically and says what each
   file is at a glance;
2. **shrinks** oversized screen recordings, in place, so they can be dropped
   straight into a Discord message.

## Key Files
| File | Description | Symlink Target |
|------|-------------|----------------|
| `Library/LaunchAgents/com.oinp.captures-tidy.plist` | Fires `captures-tidy` when `~/Pictures/Screenshots` changes | `~/Library/LaunchAgents/` |

## Dependencies
- `scripts/.local/bin/captures-tidy` — the work; the agent only triggers it
- `ffmpeg` (with `libx265`) via Homebrew — already in the Brewfile
- **Vorssaint** writes the captures. Its `recorderSaveFolder` and
  `screenshotSaveFolder` must match `WatchPaths` in the plist
  (`~/Pictures/Screenshots`); the folder is declared in
  `scripts/.local/bin/vorssaint-apply`. Change one, change the other.

## Why this exists at all

**The size half.** Vorssaint's recorder cannot be configured down to a shareable
size. It offers coarse quality presets that scale *resolution*, never bitrate,
and there is no bitrate, CRF or codec setting to reach for. Its output lands at
4.7–9.8 Mbps — a six-minute recording is 211 MB against Discord's 20 MB ceiling,
a ~10x gap that no preset in the app can express.

Worse, `recorderFrameRate` does not work. `vorssaint-apply` declares it 30 and
`defaults read com.vorssaint.utils` reads back 30, yet every file the editor
exports is 60fps. This is the same shape as the `outputScale` gap already noted
in `vorssaint-apply`: a declared setting that the export path ignores. Do not
spend time re-applying it — verify with `ffprobe`, not with `defaults read`.

**The naming half.** Vorssaint *can* name screenshots — the `File name` field
under Screenshot, stored as `screenshotFileNamePattern`, with `%y %year %mo
%month %d %h %mi %s` tokens plus `%#` for a counter. It has no equivalent for
recordings, and this is not an oversight to work around but a structural one:
the two save paths are separate functions, and only one of them reads a pattern.

```
ScreenshotService.saveDestination      → screenshotFileNamePattern, screenshotSaveSubfolder, …
ScreenRecorderService.saveDestination  → recorderSaveFolder + Date(), nothing else
```

So `Recording 2026-09-03 at 17.04.01.mp4` is built in code from the locale, and
no `defaults write` can reach it. Rather than name screenshots in Vorssaint and
recordings here — two rules that would drift — both are named here and
Vorssaint's own naming settings are left at their defaults.

This agent replaces `com.oinp.screenshots-compress`, which only compressed, and
before it `com.oinp.screenshots-to-mp4` (deleted in 46fb86e), which watched for
`.mov` and converted to `.mp4`. Vorssaint writes `.mp4` itself now.

## Why WatchPaths instead of fswatch
The deleted agent ran `KeepAlive` with a resident `fswatch` pipe. This one
declares `WatchPaths` and lets launchd's own kqueue watch fire the job, which:
- drops the `fswatch` Homebrew dependency — it is no longer installed
- has no resident process to leak, wedge or restart
- self-heals: a crashed run is simply not running, and the next file re-fires it

The cost is that launchd re-fires on *any* directory mutation, and the job makes
two of its own: every rename, and every file it replaces. The script's gates
must therefore no-op on the second pass — see the marker gotcha below.

## Setup
```bash
stow -t ~ launchd
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.oinp.captures-tidy.plist
```
`launchctl load` still works but is deprecated; `bootstrap`/`bootout` are the
supported spelling on modern macOS and give real error messages.

## Useful commands
```bash
# Is it registered, and what did it last exit with?
launchctl print gui/$(id -u)/com.oinp.captures-tidy

# Run it right now without touching the folder
launchctl kickstart -k gui/$(id -u)/com.oinp.captures-tidy

# Reload after editing the plist
launchctl bootout gui/$(id -u)/com.oinp.captures-tidy
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.oinp.captures-tidy.plist

# Logs
tail -f /tmp/captures-tidy.log
tail -f /tmp/captures-tidy.error.log
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
- **The size gate alone cannot stop a re-encode loop.** The compressed file now
  *replaces* its source, so the old `.compressed.mp4` sidecar — whose mere
  existence was the "already done" marker — is gone. A recording long enough to
  hit the `MIN_VIDEO_KBPS` floor comes out of pass 2 still above `TARGET_MB`,
  passes the size gate again on the next fire, and would lose quality on every
  pass. What stops it is a `comment=captures-tidy` tag written into the mp4 by
  pass 2 and read back with `ffprobe`. Strip that tag and the file becomes
  eligible again.
- **Renaming breaks Vorssaint's own pointer to the file.** The app stores a
  capture's path in `RecentCaptureEntry` for its recent-captures list and for the
  "Saved to …" reveal. Renaming behind it leaves the file perfectly intact and
  that shortcut pointing nowhere. The job skips any file `lsof` shows still open,
  which covers the editor mid-Save, but not a capture already listed in the app.
- **The rename matches the timestamp's shape, not the prefix.** Vorssaint builds
  `Recording 2026-09-03 at 17.04.01` from the locale, so matching the literal
  word `Recording` would break the day this Mac switches language. The test is
  `YYYY-MM-DD at HH.MM.SS` at the end of the name, and the *extension* decides
  `SS_` or `SR_`. A consequence worth knowing: a file whose name does not carry
  that shape — including the older `....compressed.mp4` outputs — is left alone.
- **The timestamp is read from the name, never from `stat`.** Compression
  rewrites the file, so its mtime carries the encode time. Renaming from mtime
  would silently relabel every recording the agent has already touched.
- **`ProcessType` is the only scheduling key that does anything**, and it is
  worth 4.5x. On Apple Silicon it decides which CPU cluster the job may use,
  with no gradual middle — `Background` and `Standard` both confine it to the
  efficiency cores, `Interactive` unlocks all of them. Same file, same script:
  474s / 231s / 105s respectively.
- **`Nice` is a red herring, do not reach for it.** It reads 19 under launchd in
  every configuration, including `Interactive` running at 792% CPU. Setting the
  key to 10 measured 234s against 231s without it. The nice value does not gate
  core access on this hardware; the QoS class does. The script cannot fix it
  from the inside either — lowering your own niceness requires privilege.
- **Framerate is nearly free; resolution is not.** At a fixed 442k budget on a
  90s slice, 1440 wide scored 0.9741 at 30fps, 0.9742 at 25 and 0.9742 at 20 —
  identical to four decimals. All of the quality difference against 1802 wide
  (0.9872) is the resize. But SSIM is a per-frame spatial metric and **cannot
  see judder**, so it says nothing about motion smoothness; judge that by eye.
- **Pick a framerate that divides the source.** Vorssaint records at 60, so 30
  (60/2) and 20 (60/3) drop frames evenly. 25 does not — 60/25 = 2.4 drops in a
  2,2,3,2,3 pattern that reads as judder on smooth scrolling. The current 20 was
  chosen for that reason over the 25 originally proposed.
- **Resizing is the wrong lever if you care about quality.** Tempting, and measurably
  counterproductive: at a fixed 442k budget, 1802 wide scored SSIM 0.9926, 1280
  scored 0.9743, 1100 scored 0.9664. Screen frames are mostly flat regions that
  cost x265 almost nothing, and the value sits in text living on the native
  pixel grid — resampling glyphs destroys detail no bitrate recovers. This is
  the opposite of camera video, where fewer pixels really does mean more bits
  each. `hevc_videotoolbox` was measured too and rejected at 0.9069. The
  current 1440 cap is a deliberate speed-for-fidelity trade made with those
  numbers in hand, not a default — raise MAX_LONG_EDGE to 1920 to undo it.
- **`plutil -lint` validates XML, not intent.** It passed happily on a version
  of this plist with the `ProcessType` key accidentally deleted. Assert real
  keys with `PlistBuddy -c 'Print :ProcessType'`.
