#!/usr/bin/env python3
"""PreToolUse hook (Bash): before a test, type or lint run in vicat or Table, refuse it
while the shared installation drifts from the checkout's lockfile.

A drifted venv or node_modules turns into failures that look like regressions and cost a
baseline run against main to clear. The comparison lives in the workspace script
`deps_check.py`; prefix the command with `DEPS_CHECK_SKIP=1` to run it anyway.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from shell_commands import split_simple_commands  # noqa: E402

DEPS_CHECK = Path("/Users/oinp/dev/sillant/.claude/scripts/deps_check.py")
RUNNERS = {"pytest", "mypy", "tsc", "jest", "vitest", "eslint"}
NPM_SCRIPTS = re.compile(r"^(test|typecheck|lint|tsc|check)(:|$)")
CHECKOUT_PATH = re.compile(r"^/Users/oinp/dev/sillant/(vicat|Table)(/|$)")
TOOL_PATH = re.compile(r"/(\.venv|node_modules)/")


def is_checked_run(words: list[str]) -> bool:
    if any(os.path.basename(word) in RUNNERS for word in words):
        return True
    if words[:1] == ["npm"]:
        script = words[2] if words[1:2] == ["run"] and len(words) > 2 else words[1:2] and words[1]
        return bool(script and NPM_SCRIPTS.match(script))
    return False


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    if "DEPS_CHECK_SKIP=1" in command or not DEPS_CHECK.exists():
        sys.exit(0)
    checked = set()
    for simple in split_simple_commands(command, payload.get("cwd", ".")):
        if not is_checked_run(simple.words):
            continue
        target = next((word for word in simple.words if CHECKOUT_PATH.match(word)
                       and not TOOL_PATH.search(word)), simple.directory)
        if target in checked:
            continue
        checked.add(target)
        result = subprocess.run([sys.executable, str(DEPS_CHECK), target], capture_output=True,
                                text=True)
        if result.returncode == 1:
            print(f"{result.stderr.strip()}\nOr prefix DEPS_CHECK_SKIP=1 to run anyway.",
                  file=sys.stderr)
            sys.exit(2)


if __name__ == "__main__":
    main()
