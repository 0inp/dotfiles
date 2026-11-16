#!/usr/bin/env python3
"""PreToolUse hook (Bash): before a `git push` from vicat or Table, run the checks the CI
would fail on, and refuse the push while they are red.

A red push costs a CI round trip and a second push. Only what the branch touches is checked,
against `origin/main`: vicat replays its Linter job (`vicat-py check`) when a `.py` file
changed; Table type-checks each workspace holding a changed `.ts`/`.tsx`. Exit code 2 is
what sends the agent back to fix it. Prefix the command with `PUSH_CHECK_SKIP=1` to push
anyway.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from shell_commands import find_git_subcommand, resolve_git_directory, split_simple_commands  # noqa: E402

SCRIPTS = Path("/Users/oinp/dev/sillant/.claude/scripts")
VICAT = "/Users/oinp/dev/sillant/vicat"
TABLE = "/Users/oinp/dev/sillant/Table"
CHECK_TIMEOUT_SECONDS = 840
OUTPUT_TAIL_LINES = 40


def read_toplevel(directory: str) -> str | None:
    result = subprocess.run(["git", "-C", directory, "rev-parse", "--show-toplevel"],
                            capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else None


def read_changed_files(toplevel: str) -> list[str]:
    result = subprocess.run(["git", "-C", toplevel, "diff", "--name-only", "--diff-filter=d",
                             "origin/main...HEAD"], capture_output=True, text=True)
    return result.stdout.split() if result.returncode == 0 else []


def collect_checks(toplevel: str) -> list[tuple[list[str], str]]:
    """(command, directory) pairs to run for this checkout, from the files its branch
    changes."""
    changed = read_changed_files(toplevel)
    if toplevel.startswith(VICAT):
        if any(path.endswith(".py") for path in changed):
            return [([str(SCRIPTS / "vicat-py"), "check"], toplevel)]
        return []
    if toplevel.startswith(TABLE):
        workspaces = sorted({path.split("/", 1)[0] for path in changed
                             if path.endswith((".ts", ".tsx")) and "/" in path})
        return [([str(SCRIPTS / "table-js"), "tsc", "--noEmit"], f"{toplevel}/{workspace}")
                for workspace in workspaces if Path(toplevel, workspace, "tsconfig.json").exists()]
    return []


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    if "PUSH_CHECK_SKIP=1" in command:
        sys.exit(0)
    checked = set()
    for simple in split_simple_commands(command, payload.get("cwd", ".")):
        subcommand = find_git_subcommand(simple.words)
        if not subcommand or subcommand[0] != "push":
            continue
        if {"--delete", "-d", "--dry-run", "-n", "--tags"} & set(subcommand[1]):
            continue
        toplevel = read_toplevel(resolve_git_directory(simple))
        if not toplevel or toplevel in checked:
            continue
        checked.add(toplevel)
        for check, directory in collect_checks(toplevel):
            try:
                result = subprocess.run(check, cwd=directory, capture_output=True, text=True,
                                        timeout=CHECK_TIMEOUT_SECONDS)
            except subprocess.TimeoutExpired:
                print(f"{' '.join(check)} timed out after {CHECK_TIMEOUT_SECONDS}s in "
                      f"{directory}. Run it by hand, or prefix PUSH_CHECK_SKIP=1.",
                      file=sys.stderr)
                sys.exit(2)
            if result.returncode != 0:
                output = (result.stdout + result.stderr).strip().splitlines()
                print("\n".join(output[-OUTPUT_TAIL_LINES:]), file=sys.stderr)
                print(f"\nPush refused: `{' '.join(check)}` failed in {directory}. Fix it, "
                      "or prefix PUSH_CHECK_SKIP=1 to push anyway.", file=sys.stderr)
                sys.exit(2)


if __name__ == "__main__":
    main()
