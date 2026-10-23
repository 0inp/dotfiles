#!/usr/bin/env python3
"""PreToolUse hook (Bash): refuse switching the branch of the main vicat or Table checkout.

Concurrent sessions share those two checkouts: the venv, node_modules, the local stack
serving manual QA and every worktree's tooling all read from them. A branch switched
there by one session silently changes what the others test and serve, so branch work
belongs in a worktree under `<clone>/.worktrees/`. Restoring files (`git checkout --
PATH`) and returning to main stay allowed. A QA the user asks for on the main checkout
goes through the workspace's `qa-switch`, which detaches it on the branch head.

A directory the hook cannot read literally (`git -C $V`, `cd $p` in a loop) may be a main
checkout, so a branch switch there is refused until the path is written out.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from shell_commands import find_git_subcommand, resolve_git_directory, split_simple_commands  # noqa: E402

MAIN_CLONES = {"/Users/oinp/dev/sillant/vicat", "/Users/oinp/dev/sillant/Table"}
DEFAULT_BRANCHES = {"main", "master"}


def read_toplevel(directory: str) -> str | None:
    result = subprocess.run(
        ["git", "-C", directory, "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    return result.stdout.strip() if result.returncode == 0 else None


def is_branch_switch(arguments: list[str]) -> bool:
    if "--" in arguments:
        return False
    targets = [argument for argument in arguments if not argument.startswith("-")]
    return not (targets and set(targets) <= DEFAULT_BRANCHES and len(targets) == 1)


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    for simple in split_simple_commands(command, payload.get("cwd", ".")):
        found = find_git_subcommand(simple.words)
        if not found or found[0] not in ("checkout", "switch") or not is_branch_switch(found[1]):
            continue
        directory = resolve_git_directory(simple)
        if "$" in directory:
            print(
                f"Refused: `git {found[0]}` runs in {directory}, a path built from a shell "
                f"variable the hook cannot resolve; it may be a main checkout. Write the "
                f"repository path out literally.",
                file=sys.stderr,
            )
            sys.exit(2)
        toplevel = read_toplevel(directory)
        if toplevel in MAIN_CLONES:
            print(
                f"Refused: `git {found[0]}` would switch the branch of the shared main checkout "
                f"{toplevel}, which other sessions and the local QA stack read from. Branch "
                f"work: git -C {toplevel} worktree add {toplevel}/.worktrees/<name> <branch>. "
                f"A QA the user asked for on the main checkout: "
                f"/Users/oinp/dev/sillant/.claude/scripts/qa-switch {Path(toplevel).name} "
                f"<branch>, then qa-switch {Path(toplevel).name} main once done.",
                file=sys.stderr,
            )
            sys.exit(2)


if __name__ == "__main__":
    main()
