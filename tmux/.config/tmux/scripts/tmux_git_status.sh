#!/bin/bash

PANE_PATH="$1"

# Get branch name
BRANCH=$(git -C "$PANE_PATH" rev-parse --abbrev-ref HEAD 2>/dev/null)

# If not a git repo or no branch, just return empty or branch name
if [ -z "$BRANCH" ]; then
	echo ""
	exit 0
fi

# Get diff stat summary
DIFF_SUMMARY=$(git -C "$PANE_PATH" diff --stat 2>/dev/null | tail -n 1)

# Parse diff summary using awk
PARSED_DIFF=$(echo "$DIFF_SUMMARY" | awk '
    /files changed/ {
        files=$1;
        insertions=0;
        deletions=0;
        for (i=2; i<=NF; i++) {
            if ($i ~ /insertion/) {
                insertions=$(i-1);
            } else if ($i ~ /deletion/) {
                deletions=$(i-1);
            }
        }
        if (files > 0) {
            printf "%s*, %s+, %s-", files, insertions, deletions;
        }
    }
')
if [ -z "$PARSED_DIFF" ]; then
	echo "$BRANCH"
else
	echo "$BRANCH $PARSED_DIFF"
fi
