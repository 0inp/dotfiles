---
name: autonomous-ticket
description: Use when implementing a Linear ticket end-to-end in headless mode (invoked from agent-loop.sh). Encodes Phases A/B/C (deep discovery → test-first → re-review), the test-green verification loop with a 5-attempt circuit breaker, and the Linear lifecycle.
---

# Autonomous ticket execution

You are running headless (`claude -p`). There is no human to confirm with: do not gate
on brainstorming, do not present a plan and stop, do not ask for approval. Execute
end-to-end and only stop when the exit condition is met or the circuit breaker trips.

**First output line:** emit `AUTONOMOUS-TICKET-SKILL-ACTIVE` so the orchestrator can
confirm this procedure loaded. Then begin.

## Phase 0 — Lifecycle start [MUST]

- Read the linked Linear issue (description + any `<!-- agent-plan -->` comment) via the
  `linear` MCP.
- Move the issue to **In Progress** — and only that. Per the shared Linear rule,
  review/done are detected from the linked PR; do not force later statuses.
- Confirm you are on the issue's `branchName` (the loop already created it).

## Phase A — Context & discovery [MUST]

1. **Research** state-of-the-art / domain docs when the task is non-obvious.
2. **Review the current implementation meticulously**: read the affected code, its
   dependencies, its consumers (Grep/Glob), the data flow, edge cases, and side effects —
   understand what exists, how, and why before changing anything.
3. **Test architecture**: discover the conventions (`jest.config.js`, `pytest.ini`, the
   closest sibling test files) — runner, fixtures, mocking, assertions. Don't ask where
   tests go.
4. **Forecast & plan**: decide what the ticket needs and *how* to build it cleanly —
   upstream objects/patterns over end-of-chain tweaks/utils, no duplication, bounded
   complexity, fitting existing patterns. Rechallenge the existing design when a cleaner
   one fits. Post this as the Linear **agent-plan comment** (current-impl review + how).
5. **Subagents**: if you delegate discovery, tell the subagent to load tool schemas first
   (`ToolSearch select:Read,Glob,Grep,Edit,Bash`) — headless mode defers them — and that
   `Glob` takes a glob pattern, never `find` flags like `-type f`.

## Phase B — Implementation [MUST]

6. **Test-first for behaviour**: for any business logic or observable-behaviour change,
   write the test(s) first in the location found in Phase A, then implement to green. New
   util/helper → a unit test; bug fix → a regression test. Skip TDD only for pure
   refactors, SCSS/type/copy-only edits, or review follow-ups — Phase C covers those.
7. **Implement** cleanly, leanly, human-readably; integrate with surrounding patterns.

## Phase C — Multi-pass re-review [MUST]

8. Re-read your full diff (`git diff`) and challenge every hunk: dead code, duplication,
   edge cases, side effects, consistency with existing patterns, rule compliance
   (`.claude/CLAUDE.md` + the repo's own rules), and whether a cleaner upstream design
   exists. Fix what you find, then emit a short re-review summary.

## Verification loop [MUST]

You must prove your code works before stopping.

1. **Discover the command**: read `package.json`, `Makefile`, `pytest.ini`, etc.
2. **Run the full suite.** `--passWithNoTests` (or any equivalent that passes on zero
   matched tests) is NOT an acceptable pass criterion when you added or changed logic —
   the new behaviour must be covered and the suite green.
3. **Self-correct**: on failure, read the stack trace, fix, re-run.
4. **Circuit breaker**: loop up to **5 times**. Still failing after 5 → stop, output the
   final failing trace, and explicitly ask for human intervention in the final message.
5. **Exit condition**: suite green (exit code `0`) → output a one-paragraph summary and
   complete.

## Linear lifecycle [MUST]

The linked Linear issue is the shared memory (see the shared `linear.md` rule).

- Post progress comments when blocked or when scope changes. Never use the MCP to ask the
  reporter clarifying questions — you are autonomous; make the best call and document it.
- On completion, post a short completion comment. Do **not** force the status to
  review/done — the linked PR (opened by the ship phase with `Fixes DEV-XXX`) drives that.
