#!/bin/sh
# Claude Code status line — inspired by Pure prompt
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

model=$(echo "$input" | jq -r '.model.display_name // ""')

# Git branch (skip optional locks to avoid blocking)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Context used
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Rate limit usage (Pro/Max subscribers only, may be absent)
session_usage=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
weekly_usage=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Build the line
line="$short_cwd"
[ -n "$branch" ] && line="$line  $branch"
[ -n "$model" ] && line="$line  $model"
[ -n "$used" ] && line="$line  used-ctx:$(printf '%.0f' "$used")%"
[ -n "$session_usage" ] && line="$line  5h:$(printf '%.0f' "$session_usage")%"
[ -n "$weekly_usage" ] && line="$line  wk:$(printf '%.0f' "$weekly_usage")%"

printf '%s' "$line"
