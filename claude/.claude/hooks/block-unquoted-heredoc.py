#!/usr/bin/env python3
"""PreToolUse hook (Bash): refuse an unquoted heredoc whose body holds backticks.

In `<<EOF` the shell runs every `...` span as a command substitution, so markdown
written through such a heredoc (a commit message, a PR body, a Linear comment) loses
its code spans and runs them instead. `<<'EOF'` keeps the body literal.
"""

import json
import re
import sys

HEREDOC = re.compile(r"<<-?\s*(?P<delimiter>[A-Za-z_][A-Za-z0-9_]*)\b")


def find_unsafe_heredoc(command: str) -> str | None:
    for match in HEREDOC.finditer(command):
        delimiter = match.group("delimiter")
        body_start = command.find("\n", match.end())
        if body_start == -1:
            continue
        terminator = re.search(rf"^\s*{delimiter}\s*$", command[body_start + 1 :], re.MULTILINE)
        body = command[body_start + 1 : body_start + 1 + terminator.start()] if terminator else command[body_start + 1 :]
        if "`" in body:
            return delimiter
    return None


def main() -> None:
    payload = json.load(sys.stdin)
    command = payload.get("tool_input", {}).get("command", "")
    delimiter = find_unsafe_heredoc(command)
    if delimiter is None:
        sys.exit(0)
    print(
        f"Unquoted heredoc <<{delimiter} contains backticks: the shell would execute them. "
        f"Quote the delimiter (<<'{delimiter}') so the body stays literal.",
        file=sys.stderr,
    )
    sys.exit(2)


if __name__ == "__main__":
    main()
