"""Split a Bash tool command into simple commands, each with the directory it runs in.

Heredoc bodies are dropped first, so text such as a commit message that mentions
`git checkout` is never mistaken for a command. `cd DIR` segments move the directory of
the commands that follow them, which is how agents usually address a nested clone.
"""

import os
import re
import shlex
from dataclasses import dataclass

HEREDOC = re.compile(r"<<-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1[^\n]*\n")
SEPARATORS = {";", "&&", "||", "|", "&", "\n", "(", ")"}
ENVIRONMENT_ASSIGNMENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*=")
# Words that open a compound command: the command they introduce follows them.
LEADING_KEYWORDS = {"do", "then", "else", "elif", "!", "time", "{"}


@dataclass(frozen=True)
class SimpleCommand:
    words: list[str]
    directory: str


def strip_heredoc_bodies(command: str) -> str:
    kept, position = [], 0
    while match := HEREDOC.search(command, position):
        kept.append(command[position : match.end()])
        terminator = re.search(rf"^\s*{match.group(2)}\s*$", command[match.end() :], re.MULTILINE)
        position = match.end() + terminator.end() if terminator else len(command)
    kept.append(command[position:])
    return "".join(kept)


def split_simple_commands(command: str, cwd: str) -> list[SimpleCommand]:
    lexer = shlex.shlex(strip_heredoc_bodies(command).replace("\n", " ; "), posix=True,
                        punctuation_chars=";&|()")
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        return []
    commands, words, directory = [], [], cwd
    for token in tokens + [";"]:
        if token not in SEPARATORS:
            words.append(token)
            continue
        while words and (ENVIRONMENT_ASSIGNMENT.match(words[0]) or words[0] in LEADING_KEYWORDS):
            words.pop(0)
        if words[:1] == ["cd"] and len(words) > 1:
            directory = os.path.normpath(os.path.join(directory, os.path.expanduser(words[1])))
        elif words:
            commands.append(SimpleCommand(words, directory))
        words = []
    return commands


def resolve_git_directory(command: SimpleCommand) -> str:
    """The directory git acts on: the last `-C DIR` before the subcommand, else the cwd."""
    directory = command.directory
    words = command.words
    for index, word in enumerate(words[:-1]):
        if word == "-C":
            directory = os.path.normpath(os.path.join(directory, os.path.expanduser(words[index + 1])))
    return directory


def find_git_subcommand(words: list[str]) -> tuple[str, list[str]] | None:
    """`git [-C DIR] [-c k=v] [--no-pager] SUBCOMMAND ARGS…`, or `rtk git …`."""
    if words[:1] == ["rtk"]:
        words = words[1:]
    if words[:1] != ["git"]:
        return None
    index = 1
    while index < len(words) and words[index].startswith("-"):
        index += 2 if words[index] in ("-C", "-c") else 1
    return (words[index], words[index + 1 :]) if index < len(words) else None
