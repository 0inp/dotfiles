#!/usr/bin/env python3
"""PreToolUse hook (Bash): before a test, type or lint run in vicat or Table, refuse it
while the shared installation drifts from the checkout's lockfile.

A drifted venv or node_modules turns into failures that look like regressions and cost a
baseline run against main to clear. The comparison lives in the workspace script
`deps_check.py`; prefix the command with `DEPS_CHECK_SKIP=1` to run it anyway.
"""

from __future__ import annotations

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
VICAT_PATH = re.compile(r"^/Users/oinp/dev/sillant/vicat(/|$)")
POETRY_ENV_TIMEOUT_SECONDS = 15


def strip_launchers(words: list[str]) -> list[str]:
    """`npx jest`, `poetry run pytest`, `timeout 600 tsc`, `python -m mypy`, `vicat-py pytest`
    → the runner itself, so only the program actually executed is matched, never an argument
    such as the path in `ls node_modules/.bin/tsc`."""
    while words:
        launcher = os.path.basename(words[0])
        if launcher in ("npx", "env", "vicat-py"):
            words = words[1:]
        elif launcher in ("poetry", "uv") and words[1:2] == ["run"]:
            words = words[2:]
        elif launcher == "timeout" and len(words) > 1:
            words = words[2:]
        elif launcher.startswith("python") and words[1:2] == ["-m"]:
            words = words[2:]
        else:
            return words
    return words


def is_checked_run(words: list[str]) -> bool:
    words = strip_launchers(words)
    if words and os.path.basename(words[0]) in RUNNERS:
        return True
    if words[:1] == ["npm"]:
        script = words[2] if words[1:2] == ["run"] and len(words) > 2 else words[1:2] and words[1]
        return bool(script and NPM_SCRIPTS.match(script))
    return False


def find_target_path(words: list[str], directory: str) -> str:
    """The first argument naming an existing path inside vicat or Table (`price-bible/src`,
    `--config=price-bible/jest.config.js`), so the check covers the npm workspace the run
    loads; else the directory the command runs in."""
    for word in words[1:]:
        path = os.path.normpath(os.path.join(directory, word.split("=", 1)[-1]))
        if CHECKOUT_PATH.match(path) and not TOOL_PATH.search(path) and os.path.exists(path):
            return path
    return directory


def find_command_python(words: list[str], directory: str) -> str | None:
    """The interpreter a vicat command really loads when it is not the shared price_bible
    venv: the `bin/python` beside a runner called by its venv path, or the Poetry env of
    the directory for `poetry run`. None keeps deps_check on the shared venv, which is what
    `vicat-py` runs."""
    if not VICAT_PATH.match(os.path.normpath(directory)):
        return None
    runner = strip_launchers(words)
    if runner and "/bin/" in runner[0]:
        python = os.path.join(os.path.dirname(os.path.join(directory, runner[0])), "python")
        return python if os.path.exists(python) else None
    launchers = [os.path.basename(word) for word in words[: len(words) - len(runner)]]
    if not any(launchers[i : i + 2] == ["poetry", "run"] for i in range(len(launchers))):
        return None
    try:
        result = subprocess.run(["poetry", "env", "info", "--executable"], cwd=directory,
                                capture_output=True, text=True,
                                timeout=POETRY_ENV_TIMEOUT_SECONDS)
    except (OSError, subprocess.TimeoutExpired):
        return None
    python = result.stdout.strip()
    return python if result.returncode == 0 and os.path.exists(python) else None


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    if "DEPS_CHECK_SKIP=1" in command or not DEPS_CHECK.exists():
        sys.exit(0)
    checked = set()
    for simple in split_simple_commands(command, payload.get("cwd", ".")):
        if not is_checked_run(simple.words):
            continue
        target = find_target_path(simple.words, simple.directory)
        if target in checked:
            continue
        checked.add(target)
        python = find_command_python(simple.words, simple.directory)
        arguments = [target, "--python", python] if python else [target]
        result = subprocess.run([sys.executable, str(DEPS_CHECK), *arguments],
                                capture_output=True, text=True)
        if result.returncode == 1:
            print(f"{result.stderr.strip()}\nOr prefix DEPS_CHECK_SKIP=1 to run anyway.",
                  file=sys.stderr)
            sys.exit(2)


if __name__ == "__main__":
    main()
