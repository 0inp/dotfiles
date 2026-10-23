#!/usr/bin/env python3
"""PostToolUse hook (Write|Edit|Bash): flag a memory index that outgrows what gets loaded.

Claude Code loads MEMORY.md truncated past ~24.4 KB or 200 lines, cutting from the end,
where new entries are appended: the most recent lessons are the ones silently dropped.
The budget below keeps headroom so the next append still fits.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

MAX_BYTES = 23_000
MAX_LINES = 150
INDEX_PATH = re.compile(r"(~?/[^\s'\"]*/memory/MEMORY\.md)")


def find_index_paths(payload: dict) -> set[Path]:
    tool_input = payload.get("tool_input", {})
    candidates = [tool_input.get("file_path", "")] + INDEX_PATH.findall(tool_input.get("command", ""))
    return {Path(candidate).expanduser() for candidate in candidates
            if candidate.endswith("memory/MEMORY.md")}


def main() -> None:
    payload = json.load(sys.stdin)
    for index in find_index_paths(payload):
        if not index.exists():
            continue
        content = index.read_bytes()
        size, lines = len(content), content.count(b"\n")
        if size > MAX_BYTES or lines > MAX_LINES:
            print(
                f"{index} is {size} bytes / {lines} lines (budget {MAX_BYTES} / {MAX_LINES}): "
                f"entries past the load limit are dropped from the end. Shorten hooks or group "
                f"related entries on one line, keeping every file linked.",
                file=sys.stderr,
            )
            sys.exit(2)


if __name__ == "__main__":
    main()
