#!/usr/bin/env python3
"""PreToolUse hook (Bash): refuse `gh pr merge --delete-branch` while PRs still target it.

Deleting a branch on GitHub closes every open PR whose base is that branch, and a
closed PR cannot be retargeted: the child of a stack disappears from review. The child
must be retargeted onto the parent's base before the parent merges with branch deletion.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from shell_commands import split_simple_commands  # noqa: E402

DELETE_FLAGS = {"--delete-branch", "-d"}
REPOSITORY_FLAGS = {"-R", "--repo"}


def read_option(arguments: list[str], names: set[str]) -> str | None:
    for index, argument in enumerate(arguments):
        if argument in names and index + 1 < len(arguments):
            return arguments[index + 1]
        for name in names:
            if argument.startswith(f"{name}="):
                return argument.split("=", 1)[1]
    return None


def run_gh(arguments: list[str], directory: str) -> list | dict | None:
    result = subprocess.run(["gh", *arguments], capture_output=True, text=True, cwd=directory)
    return json.loads(result.stdout) if result.returncode == 0 and result.stdout.strip() else None


def find_open_children(arguments: list[str], directory: str) -> tuple[str, list[dict]] | None:
    repository = read_option(arguments, REPOSITORY_FLAGS)
    repository_arguments = ["-R", repository] if repository else []
    option_values = {arguments[index + 1] for index, argument in enumerate(arguments[:-1])
                     if argument in REPOSITORY_FLAGS}
    selector = [argument for argument in arguments[3:]
                if not argument.startswith("-") and argument not in option_values][:1]
    parent = run_gh(["pr", "view", *selector, *repository_arguments, "--json", "headRefName"],
                    directory)
    if not parent:
        return None
    head = parent["headRefName"]
    children = run_gh(["pr", "list", "--base", head, "--state", "open", *repository_arguments,
                       "--json", "number,title"], directory) or []
    return head, children


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    for simple in split_simple_commands(command, payload.get("cwd", ".")):
        words = simple.words
        if words[:3] != ["gh", "pr", "merge"] or not DELETE_FLAGS & set(words):
            continue
        found = find_open_children(words, simple.directory)
        if found and found[1]:
            head, children = found
            listed = ", ".join(f"#{child['number']}" for child in children)
            print(
                f"Refused: deleting `{head}` would close the open PRs based on it ({listed}). "
                f"Retarget them first (gh pr edit <n> --base <parent's base>), then merge.",
                file=sys.stderr,
            )
            sys.exit(2)


if __name__ == "__main__":
    main()
