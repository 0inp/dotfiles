#!/usr/bin/env python3
"""PreToolUse hook (Bash): refuse an npm install that would rewrite the shared node_modules.

Table worktrees link their node_modules to the main checkout's, and `npm ci` starts by
deleting node_modules: run from such a worktree, it empties the tree every other session
is testing against. Installs belong in the main checkout, or in a worktree whose
node_modules is a real directory of its own.

Run from an npm workspace directory (`Table/price-bible/`), `npm ci` also empties the root
node_modules but reinstalls that workspace alone: eslint loses `@eslint/js` and the other
workspaces their packages. Installs run from the repository root.
"""

from __future__ import annotations

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


def read_repository_root(directory: str) -> Path | None:
    result = subprocess.run(["git", "-C", directory, "rev-parse", "--show-toplevel"],
                            capture_output=True, text=True)
    return Path(result.stdout.strip()) if result.returncode == 0 else None


def is_npm_workspace(root: Path, directory: str) -> bool:
    try:
        workspaces = json.loads((root / "package.json").read_text()).get("workspaces", [])
    except (OSError, ValueError):
        return False
    return any(Path(directory) == root / workspace for workspace in workspaces)


def find_linked_node_modules(root: Path) -> Path | None:
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
        root = read_repository_root(directory)
        if root is None:
            continue
        if is_npm_workspace(root, directory) and "--workspace" not in " ".join(simple.words):
            print(
                f"Refused: `npm {simple.words[1]}` from the npm workspace {directory} empties "
                f"the root node_modules and reinstalls this workspace alone (eslint then "
                f"misses @eslint/js). Run it from the repository root: cd {root} && npm "
                f"{simple.words[1]}.",
                file=sys.stderr,
            )
            sys.exit(2)
        linked = find_linked_node_modules(root)
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
