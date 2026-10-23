#!/usr/bin/env python3
"""PreToolUse hook (Bash): refuse an npm install that would rewrite the shared node_modules.

Table worktrees link their node_modules to the main checkout's, and `npm ci` starts by
deleting node_modules: run from such a worktree, it empties the tree every other session
is testing against. Installs belong in the main checkout, or in a worktree whose
node_modules is a real directory of its own.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from shell_commands import split_simple_commands  # noqa: E402

INSTALL_SUBCOMMANDS = {"ci", "install", "i", "add", "uninstall", "remove", "rm", "update", "up",
                       "dedupe", "prune"}


def find_npm_directory(words: list[str], directory: str) -> str | None:
    """The directory an `npm <install>` acts on, or None when the command is no install."""
    if words[:1] != ["npm"]:
        return None
    index, prefix = 1, None
    while index < len(words) and words[index].startswith("-"):
        if words[index] in ("--prefix", "-C") and index + 1 < len(words):
            prefix = words[index + 1]
            index += 2
            continue
        index += 1
    if index >= len(words) or words[index] not in INSTALL_SUBCOMMANDS:
        return None
    return os.path.normpath(os.path.join(directory, os.path.expanduser(prefix or ".")))


def find_linked_node_modules(directory: str) -> Path | None:
    result = subprocess.run(["git", "-C", directory, "rev-parse", "--show-toplevel"],
                            capture_output=True, text=True)
    if result.returncode != 0:
        return None
    root = Path(result.stdout.strip())
    workspaces = [path.parent for path in root.glob("*/package.json")]
    candidates = [root / "node_modules", *(workspace / "node_modules" for workspace in workspaces)]
    return next((candidate for candidate in candidates if candidate.is_symlink()), None)


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    for simple in split_simple_commands(command, payload.get("cwd", ".")):
        directory = find_npm_directory(simple.words, simple.directory)
        if directory is None:
            continue
        linked = find_linked_node_modules(directory)
        if linked:
            print(
                f"Refused: `npm {' '.join(simple.words[1:3])}` in {directory} would rewrite "
                f"{linked}, a link to the node_modules every other session shares (npm ci "
                f"empties it first). Repair the shared install from the main checkout "
                f"(cd /Users/oinp/dev/sillant/Table && npm ci), or replace the link with a "
                f"real directory before installing into this worktree.",
                file=sys.stderr,
            )
            sys.exit(2)


if __name__ == "__main__":
    main()
