#!/bin/bash
# @vicinae.schemaVersion 1
# @vicinae.title airmedia
# @vicinae.description Mount the Air's media on ~/AirMedia and open it in Finder
# @vicinae.mode silent
# @vicinae.packageName dotfiles

# -d: the launcher cannot hold a foreground mount, so rclone daemonizes.
# Eject in Finder to unmount.
exec "$HOME/.local/bin/airmedia" -d
