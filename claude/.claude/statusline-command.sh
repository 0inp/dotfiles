#!/bin/sh
# Claude Code status line — inspired by Pure prompt
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

model=$(echo "$input" | jq -r '.model.display_name // ""')

# Git branch (skip optional locks to avoid blocking)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

# Context remaining
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Build the line
line="$short_cwd"
[ -n "$branch" ] && line="$line  $branch"
[ -n "$model" ] && line="$line  $model"
[ -n "$remaining" ] && line="$line  ctx:$(printf '%.0f' "$remaining")%"

printf '%s' "$line"
