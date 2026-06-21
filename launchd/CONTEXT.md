# Launchd Module Context

## Purpose
macOS LaunchAgents for background automation tasks.

## Key Files
| File | Description | Symlink Target |
|------|-------------|----------------|
| `Library/LaunchAgents/com.oinp.screenshots-to-mp4.plist` | Auto-converts new `.mov` screen recordings to `.mp4` via ffmpeg | `~/Library/LaunchAgents/` |

## Dependencies
- `scripts/screenshots-to-mp4.sh` — the watcher script invoked by the agent
- `fswatch` and `ffmpeg` via Homebrew

## Setup
```bash
stow -t ~ launchd
launchctl load ~/Library/LaunchAgents/com.oinp.screenshots-to-mp4.plist
```

## Useful commands
```bash
# Check agent status
launchctl list | grep oinp

# Reload after plist changes
launchctl unload ~/Library/LaunchAgents/com.oinp.screenshots-to-mp4.plist
launchctl load   ~/Library/LaunchAgents/com.oinp.screenshots-to-mp4.plist

# View logs
tail -f /tmp/screenshots-to-mp4.log
tail -f /tmp/screenshots-to-mp4.error.log
```
