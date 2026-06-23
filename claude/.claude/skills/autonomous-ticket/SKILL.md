---
name: autonomous-ticket
description: Use when implementing a Linear ticket end-to-end in headless mode (invoked from agent-loop.sh). Encodes the Phases A/B/C discovery → test → review workflow and the verification loop with a 5-attempt circuit breaker.
---

# Autonomous ticket execution

You are running headless (`claude -p`). There is no human to confirm with. Do not gate on brainstorming alignment, do not present a plan and stop, do not ask for approval. Execute the ticket end-to-end and only stop when the exit condition is met or the circuit breaker trips.

## Phase A — Context & Discovery

1. **Research:** Search and fetch state-of-the-art documentation and empirical data related to the domain before writing code.
2. **Evaluate:** Read the current implementation, its dependencies, and downstream effects. Use Grep/Glob to understand how the affected code is consumed.
3. **Test Architecture:** Inspect the repository to determine testing conventions (check `pytest.ini`, `jest.config.js`, file trees). Read the closest existing test files to understand mocking strategies, fixtures, and assertions. Do not ask where to put tests.

## Phase B — Implementation

4. **Test Creation First (when applicable):** For tickets adding business logic or fixing observable behavior, create the test file first in the location discovered in Phase A, then implement. For pure refactors, SCSS-only changes, type-only edits, copy edits, or PR-review follow-ups, skip TDD — Phase C's verification loop is sufficient.
5. **Implementation:** When tests come first, implement the application logic to make them pass. Otherwise, implement directly.

## Phase C — Multi-Pass Review

6. **Self-Review:** Audit your own changes for dead code, duplication, and adherence to the architectural mindset in `.claude/CLAUDE.md`. Read the diff with `git diff` and challenge each hunk.

## Verification & Internal Looping

You must prove your code works before stopping.

1. **Discover the command:** Read `package.json`, `Makefile`, `pytest.ini`, etc. to determine how tests are executed.
2. **Execute:** Run the test command.
3. **Self-correct:** If tests fail, analyze the stack trace, fix the code, re-run.
4. **Circuit breaker:** Loop up to **5 times** maximum. If tests still fail after 5 attempts, stop, output the final failing stack trace, and explicitly ask for human intervention via the final stdout message.
5. **Exit condition:** Tests pass (exit code `0`) → output a one-paragraph summary of the implemented feature and complete the task.

## Linear MCP (available in-session)

The `linear` MCP server is configured. Use it for:
- Posting progress comments on the ticket as you go (especially when blocked or when the scope changes).
- Updating the ticket status when done (e.g. to "In Review").
- Fetching related/blocking tickets for context.

Do **not** use it to ask the reporter clarifying questions — you are autonomous; make the best judgment call and document it in the comment.
