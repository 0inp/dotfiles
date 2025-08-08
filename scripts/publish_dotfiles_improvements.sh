#!/usr/bin/env bash
set -euo pipefail

# Publishes a new Notion page under the MCP Contents page with dotfiles improvements.
#
# Requirements:
# - `mcp notionApi` CLI must be installed and authenticated (NOTION_TOKEN)
# - Environment variable MCP_CONTENTS_NOTION_PAGE_ID set to the parent page ID.

PAGE_TITLE="Dotfiles improvements"
PARENT_PAGE_ID="${MCP_CONTENTS_NOTION_PAGE_ID:-}"
CONTENT_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../docs/notion/dotfiles_improvements.md"

if [[ -z "$PARENT_PAGE_ID" ]]; then
  echo "Error: MCP_CONTENTS_NOTION_PAGE_ID is not set."
  exit 1
fi

if [[ ! -f "$CONTENT_FILE" ]]; then
  echo "Error: content file not found at $CONTENT_FILE"
  exit 1
fi

echo "Creating Notion page '$PAGE_TITLE' under parent page '$PARENT_PAGE_ID'..."
mcp notionApi pages.create \
  --parent "$PARENT_PAGE_ID" \
  --title "$PAGE_TITLE" \
  --markdown < "$CONTENT_FILE"

echo "Done."
