#!/bin/bash

# Detect Homebrew prefix (works on Intel + Apple Silicon)
if command -v brew &>/dev/null; then
    HOMEBREW_PREFIX=$(brew --prefix)
else
    # Fallback detection
    if [[ $(uname -m) == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
fi

WATCH_DIR="$HOME/Pictures/Screenshots"
FFMPEG="$HOMEBREW_PREFIX/bin/ffmpeg"
FSWATCH="$HOMEBREW_PREFIX/bin/fswatch"

wait_until_closed() {
  local file="$1"
  sleep 2
  while /usr/sbin/lsof -- "$file" >/dev/null 2>&1; do
    sleep 2
  done
}

convert_to_mp4() {
  local mov="$1"
  local mp4="${mov%.mov}.mp4"
  local lock="${mov%.mov}.converting"
  [[ -f "$mp4" ]] && return
  [[ -f "$lock" ]] && return
  touch "$lock"
  wait_until_closed "$mov"
  "$FFMPEG" -i "$mov" -vcodec libx264 -crf 23 -preset slow -vf "scale=-2:1080" "$mp4" -y 2>&1
  if [[ $? -eq 0 ]]; then
    rm -f "$mov"
  fi
  rm -f "$lock"
}

"$FSWATCH" -0 "$WATCH_DIR" | while IFS= read -r -d "" file; do
  [[ "$file" == *.mov ]] || continue
  convert_to_mp4 "$file" &
done
