# Claude Code mods (usage-band + subject-todo) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build two Claude Code mods in `claude-mods/`. `usage-band` draws the
usage band above the prompt. `subject-todo` keeps a per-subject todo pane that
Claude and the user update together.

**Architecture:** Each mod is a plugin with a thin `register.ts` that wires
Claude Code events to **pure modules**: pace, layout, git parsing, binding,
subject ops, store, and the pane tree. The pure modules are unit-tested with
`node --test`, and the glue is type-checked against vendored mods types. The
work runs in two phases. **Phase 1 (Tasks 1-11) is inert**: nothing under `~`
changes and no settings file is touched. **Phase 2 (Tasks 12-13) is gated** on
Claude Code ≥ 2.1.287 reaching the Homebrew stable cask.

**Tech Stack:** TypeScript 7 (`tsc`, from mise `npm:typescript`), Node 26
(native type stripping, `node:test`), and the Claude Code mods API.

**Spec:** `docs/superpowers/specs/2026-10-07-claude-mods-design.md`

## Global Constraints

- Mods need Claude Code ≥ 2.1.287. The installed version is 2.1.285 from the
  Homebrew **stable** cask, and the user keeps that cask. No `@latest`.
- **No running Claude session may be affected.** Before Task 13: do not edit
  `claude/.claude/settings.json`, do not run `claude plugin install` or
  `claude plugin marketplace add`, do not stow anything new, and do not touch
  `~/.claude`.
- `claude-mods/` is not a stow package. Its `.stow-local-ignore` is `^.*$`,
  following the `docs/` precedent.
- Hooks modules run in an environment with **no Node and no DOM**, only web
  APIs. Files under `*/hooks/` must not import `node:*`. Tests under
  `*/tests/` may.
- Colours are ANSI-16 theme slot names only (`green`, `yellow`, `red`, `gray`,
  `blue`, `magenta`, `cyan`). Never hex.
- Levels: `OK` → `green`, `WARNING` → `yellow`, `DANGER` → `red`, no data → `gray`.
- Context: `< 40` OK, `≥ 40` WARNING, `≥ 80` DANGER.
- Pace: `budget = elapsed / window × 100`. `used < floor` → OK.
  `used ≥ budget` → DANGER. `used ≥ 0.8 × budget` → WARNING. Floors are 10
  (5h) and 5 (7d). No `resetsAt` → no data.
- No cost segment in the band.
- Row-2 shedding order, first dropped first: `↻` countdowns → 7d → 5h → effort → bar.
- The ticket template is hard-coded, with the 11 French steps from the spec.
- Commit messages are conventional (`feat(claude-mods): …`) and end with the
  repo's `Co-Authored-By` line. Commit only the files of the task:
  `CLAUDE.md`, `nvim/**` and `tuxedo/**` have unrelated uncommitted edits by
  the user. **Never push.** The user pushes.

### Deliberate deviations from the spec (found while planning)

1. **No `$.state`, no `types/index.d.ts`.** The types say *"at run time the
   import [from `'claude-code'`] is empty"*, so the `atom`/`read`/`update`
   helpers are not safe to rely on blind. Module variables plus
   `$.ui.invalidate` do the same job, and `session.start` refires after a
   module reload, which restores the subject from `$.store`.
2. **`Item` gains `changedAt`.** The spec's "validated from the pane since the
   previous prompt" needs a timestamp.
3. **`/todo` opens the pane and Esc closes it** (`closeOnEscape`), instead of a
   toggle. A toggle needs pane-open tracking for no real gain.
4. **Pure-logic tests are `*.spec.ts` run by `node --test`**, not
   `claude plugin test`, because that command does not exist on 2.1.285.
   Integration tests through `claude plugin test` are a follow-up, once the
   `claude-code/testing` kit can actually run.
5. **Glyph colours sit on a `Text` beside the item `Button`.** `Button` takes
   no `color` prop.

## Review Focus

1. **A very narrow band** (< 20 columns): no row may exceed the width. In the
   worst case, row 2 falls back to a clipped model name. Pinned by the
   all-widths property test in Task 3.
2. **Not a git repo, or `git` failing**: row 1 shows the path only and never
   throws. Pinned by the `parseStatus('')` test in Task 4, plus the try/catch
   in Task 5.
3. **A corrupt or foreign value in `$.store`**: it reads as "no subject" and
   never crashes the pane. Pinned by the `loadSubject` test in Task 8.
4. **Two sessions editing the same ticket**: a write must not drop the other
   session's item. Pinned by the interleaved-writer test in Task 8.
5. **A Linear link pasted later in a session already bound to another
   ticket**: no silent rebind. Pinned by the `ticketToBind` test in Task 6.

---

## File structure

```
claude-mods/
├── .stow-local-ignore              ^.*$  (not a stow package)
├── .claude-plugin/marketplace.json marketplace "dotfiles-mods"
├── CONTEXT.md                      loading, dev loop, tests, rollback
├── check.sh                        node --test + tsc
├── tsconfig.json                   type-checks */hooks/**/*.ts
├── types/claude-code.d.ts          vendored mods types (regenerate with /plugin-types)
├── usage-band/
│   ├── .claude-plugin/plugin.json
│   ├── hooks/hooks.json            {"modules": ["./register.ts"]}
│   ├── hooks/pace.ts               levels: context fill + pace       (pure)
│   ├── hooks/layout.ts             rows, shortenPath, shedding        (pure)
│   ├── hooks/git.ts                porcelain v2 + worktree parsing    (pure)
│   ├── hooks/register.ts           events → state → AbovePrompt tree  (glue)
│   └── tests/{pace,layout,git}.spec.ts
└── subject-todo/
    ├── .claude-plugin/plugin.json
    ├── hooks/hooks.json
    ├── hooks/binding.ts            Linear URL / branch → ticket key   (pure)
    ├── hooks/template.ts           the 11-step ticket template        (data)
    ├── hooks/subject.ts            model, tool actions, context text  (pure)
    ├── hooks/store.ts              $.store adapter, re-read, prune    (pure over KV)
    ├── hooks/pane.ts               pane element tree                  (pure over Elements)
    ├── hooks/register.ts           events, tool, command              (glue)
    └── tests/{binding,subject,store,pane}.spec.ts
```

Also modified: `CONTEXT_MAP.md` (Task 11), `lefthook.yml` (Task 11), and
`claude/.claude/settings.json` (**Task 13 only**).

---

## Phase 1: inert (safe now)

### Task 1: Scaffold `claude-mods/` and the check script

**Files:**
- Create: `claude-mods/.stow-local-ignore`, `claude-mods/.claude-plugin/marketplace.json`,
  `claude-mods/tsconfig.json`, `claude-mods/check.sh`, `claude-mods/types/claude-code.d.ts`
- Create: `claude-mods/usage-band/.claude-plugin/plugin.json`, `claude-mods/usage-band/hooks/hooks.json`,
  `claude-mods/usage-band/hooks/register.ts`
- Create: `claude-mods/subject-todo/.claude-plugin/plugin.json`, `claude-mods/subject-todo/hooks/hooks.json`,
  `claude-mods/subject-todo/hooks/register.ts`

**Interfaces:**
- Produces: `bash claude-mods/check.sh`, which every later task runs. It exits
  non-zero if a spec fails or if `tsc` reports an error.

- [ ] **Step 1: Write the stow ignore and the marketplace**

`claude-mods/.stow-local-ignore`:
```
^.*$
```

`claude-mods/.claude-plugin/marketplace.json`:
```json
{
  "name": "dotfiles-mods",
  "owner": { "name": "Stephane Point" },
  "plugins": [
    {
      "name": "usage-band",
      "source": "./usage-band",
      "description": "Context and rate-limit usage, coloured by pace, above the prompt"
    },
    {
      "name": "subject-todo",
      "source": "./subject-todo",
      "description": "A todo pane per subject (ticket or conversation) that Claude keeps up to date"
    }
  ]
}
```

- [ ] **Step 2: Write both plugin manifests, hooks.json files and stub modules**

`claude-mods/usage-band/.claude-plugin/plugin.json`:
```json
{
  "name": "usage-band",
  "version": "0.1.0",
  "description": "Context and rate-limit usage, coloured by pace, above the prompt",
  "author": { "name": "Stephane Point" }
}
```

`claude-mods/subject-todo/.claude-plugin/plugin.json`:
```json
{
  "name": "subject-todo",
  "version": "0.1.0",
  "description": "A todo pane per subject (ticket or conversation) that Claude keeps up to date",
  "author": { "name": "Stephane Point" }
}
```

Both `hooks/hooks.json`:
```json
{
  "modules": ["./register.ts"]
}
```

Both `hooks/register.ts`. They are stubs, replaced in Tasks 5 and 10:
```ts
import type { On } from 'claude-code'

export function register(_on: On): void {}
```

- [ ] **Step 3: Vendor the types and write tsconfig**

```bash
curl -fsSL https://raw.githubusercontent.com/anthropics/claude-code/main/mods/types/claude-code.d.ts \
  -o claude-mods/types/claude-code.d.ts
head -1 claude-mods/types/claude-code.d.ts   # expect "// Written by Claude Code 2.1.xxx."
```

`claude-mods/tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "es2024",
    "lib": ["es2024"],
    "module": "preserve",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "erasableSyntaxOnly": true,
    "noEmit": true,
    "strict": true,
    "skipLibCheck": true,
    "types": []
  },
  "include": ["types/claude-code.d.ts", "*/hooks/**/*.ts"]
}
```

`erasableSyntaxOnly` forbids `enum` and `namespace`, so Node's type stripping
runs the same files that `tsc` checks. Tests are excluded from `tsc` because
`@types/node` is not installed. Node runs them directly.

- [ ] **Step 4: Write the check script**

`claude-mods/check.sh`:
```bash
#!/usr/bin/env bash
# Pure-logic specs (node --test) and a type-check of every hooks module against
# the vendored mods types. Runs without Claude Code, so it works on any version.
set -euo pipefail
cd "$(dirname "$0")"

shopt -s nullglob
specs=(*/tests/*.spec.ts)
if ((${#specs[@]})); then
  node --test "${specs[@]}"
fi
tsc -p tsconfig.json
```

```bash
chmod +x claude-mods/check.sh
```

- [ ] **Step 5: Run the checks**

Run: `bash claude-mods/check.sh && bash scripts/checks.sh stow`
Expected: `tsc` prints nothing, and stow prints `✅ all modules stowed`. The
`^.*$` ignore makes `stow -n -v` print no `LINK:` line for `claude-mods`.

Run: `stow -n -v -t ~ claude-mods`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add claude-mods/
git commit -m "feat(claude-mods): scaffold the dotfiles-mods marketplace

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: `pace.ts`: context and pace levels

**Files:**
- Create: `claude-mods/usage-band/hooks/pace.ts`
- Test: `claude-mods/usage-band/tests/pace.spec.ts`

**Interfaces:**
- Produces:
  - `type Level = 'ok' | 'warning' | 'danger' | 'none'`
  - `type WindowKind = 'five_hour' | 'seven_day'`
  - `WINDOW_MS: Record<WindowKind, number>`
  - `FLOOR: Record<WindowKind, number>`
  - `contextLevel(percent: number | undefined): Level`
  - `paceLevel(kind: WindowKind, used: number, resetsAt: string | undefined, now: number): Level`

- [ ] **Step 1: Write the failing test**

`claude-mods/usage-band/tests/pace.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { contextLevel, paceLevel } from '../hooks/pace.ts'

const NOW = Date.parse('2026-10-07T12:00:00Z')
const MIN = 60_000
const H = 60 * MIN
const D = 24 * H
const resetIn = (ms: number) => new Date(NOW + ms).toISOString()

test('context: fixed thresholds at 40 and 80', () => {
  assert.equal(contextLevel(undefined), 'none')
  assert.equal(contextLevel(0), 'ok')
  assert.equal(contextLevel(39), 'ok')
  assert.equal(contextLevel(40), 'warning')
  assert.equal(contextLevel(79), 'warning')
  assert.equal(contextLevel(80), 'danger')
})

test('5h, 4h elapsed: budget 80, warning from 64', () => {
  const r = resetIn(1 * H)
  assert.equal(paceLevel('five_hour', 60, r, NOW), 'ok')
  assert.equal(paceLevel('five_hour', 64, r, NOW), 'warning')
  assert.equal(paceLevel('five_hour', 70, r, NOW), 'warning')
  assert.equal(paceLevel('five_hour', 80, r, NOW), 'danger')
  assert.equal(paceLevel('five_hour', 85, r, NOW), 'danger')
})

test('7d, day 2: budget 28.6, 41 is danger', () => {
  assert.equal(paceLevel('seven_day', 41, resetIn(5 * D), NOW), 'danger')
  assert.equal(paceLevel('seven_day', 20, resetIn(5 * D), NOW), 'ok')
})

test('floors silence the start of a window', () => {
  const r = resetIn(5 * H - 10 * MIN) // 10 min into the window, budget 3.3
  assert.equal(paceLevel('five_hour', 4, r, NOW), 'ok')
  assert.equal(paceLevel('five_hour', 12, r, NOW), 'danger')
  assert.equal(paceLevel('seven_day', 4, resetIn(7 * D - H), NOW), 'ok')
})

test('no or unreadable resetsAt gives no data', () => {
  assert.equal(paceLevel('five_hour', 50, undefined, NOW), 'none')
  assert.equal(paceLevel('five_hour', 50, 'not a date', NOW), 'none')
})

test('a reset already in the past counts as a full window', () => {
  assert.equal(paceLevel('five_hour', 85, resetIn(-MIN), NOW), 'warning')
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/usage-band/tests/pace.spec.ts`
Expected: FAIL, `Cannot find module '…/hooks/pace.ts'`.

- [ ] **Step 3: Write the constants and `contextLevel`, and stub `paceLevel`**

`claude-mods/usage-band/hooks/pace.ts`:
```ts
// The two colour rules of the usage band. Pure: no mods API, so the specs run
// under plain node.

export type Level = 'ok' | 'warning' | 'danger' | 'none'
export type WindowKind = 'five_hour' | 'seven_day'

export const WINDOW_MS: Record<WindowKind, number> = {
  five_hour: 5 * 3_600_000,
  seven_day: 7 * 86_400_000,
}

// Below this much usage a window is never coloured: early in a window the
// budget is tiny, and one request would otherwise turn it red.
export const FLOOR: Record<WindowKind, number> = { five_hour: 10, seven_day: 5 }

export function contextLevel(percent: number | undefined): Level {
  if (percent === undefined) return 'none'
  if (percent >= 80) return 'danger'
  if (percent >= 40) return 'warning'
  return 'ok'
}

// Compares usage with the share of the window that has already elapsed.
export function paceLevel(
  kind: WindowKind,
  used: number,
  resetsAt: string | undefined,
  now: number,
): Level {
  // HUMAN CONTRIBUTION, see Step 4
  return 'none'
}
```

- [ ] **Step 4: Human contribution — the user writes `paceLevel`**

This is the band's only real business rule. Hand it to the user, with the
spec's pace block and the tests above. The reference below is for reviewing
their version, not for pasting first:

```ts
  if (resetsAt === undefined) return 'none'
  const reset = Date.parse(resetsAt)
  if (Number.isNaN(reset)) return 'none'
  if (used < FLOOR[kind]) return 'ok'
  const windowMs = WINDOW_MS[kind]
  const elapsed = Math.min(windowMs, Math.max(0, windowMs - (reset - now)))
  const budget = (elapsed / windowMs) * 100
  if (used >= budget) return 'danger'
  if (used >= 0.8 * budget) return 'warning'
  return 'ok'
```

- [ ] **Step 5: Run the test to verify that it passes**

Run: `node --test claude-mods/usage-band/tests/pace.spec.ts`
Expected: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add claude-mods/usage-band/hooks/pace.ts claude-mods/usage-band/tests/pace.spec.ts
git commit -m "feat(claude-mods): pace and context levels for the usage band

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: `layout.ts`: rows, path shortening, shedding

**Files:**
- Create: `claude-mods/usage-band/hooks/layout.ts`
- Test: `claude-mods/usage-band/tests/layout.spec.ts`

**Interfaces:**
- Consumes: `Level` from `./pace.ts`
- Produces:
  - `type Tone = Level | 'path' | 'worktree' | 'branch' | 'model' | 'dim' | 'staged' | 'modified' | 'plain'`
  - `type Segment = { text: string; tone: Tone }` and `type Row = Segment[]`
  - `width(row: Row): number`, which counts code points
  - `shortenPath(p: string, max: number): string`
  - `type Row1Input = { cwd: string; home: string; worktree?: string; branch?: string; staged: number; modified: number }`
  - `composeRow1(input: Row1Input, cols: number): Row`
  - `type Limit = { label: '5h' | '7d'; percent: number; level: Level; countdown?: string }`
  - `type Row2Input = { model: string; effort?: string; contextPct?: number; contextLevel: Level; limits: Limit[] }`
  - `composeRow2(input: Row2Input, cols: number): Row`
  - `bar(pct: number): string`
  - `formatCountdown(ms: number): string`

- [ ] **Step 1: Write the failing test**

`claude-mods/usage-band/tests/layout.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  bar, composeRow1, composeRow2, formatCountdown, shortenPath, width,
  type Row, type Row2Input,
} from '../hooks/layout.ts'

const text = (row: Row) => row.map((s) => s.text).join('')

test('shortenPath: returns the path untouched when it fits', () => {
  assert.equal(shortenPath('~/dotfiles', 20), '~/dotfiles')
})

test('shortenPath: elides the middle and keeps trailing parts', () => {
  assert.equal(shortenPath('~/code/sillant/table/apps/web', 20), '~/…/table/apps/web')
})

test('shortenPath: clips the head as a last resort', () => {
  assert.equal(shortenPath('~/a/b/averylongleafname', 16), '…erylongleafname')
})

const ROW1 = { cwd: '/Users/me/dotfiles', home: '/Users/me', worktree: 'tooling-refresh', branch: 'chore/x', staged: 2, modified: 1 }

test('row 1: everything fits', () => {
  assert.equal(text(composeRow1(ROW1, 80)), '~/dotfiles  ⌂ tooling-refresh  ⑂ chore/x +2 ~1')
})

test('row 1: dirty counts carry git colours', () => {
  const row = composeRow1(ROW1, 80)
  assert.equal(row.find((s) => s.text === ' +2')?.tone, 'staged')
  assert.equal(row.find((s) => s.text === ' ~1')?.tone, 'modified')
})

test('row 1: the worktree chip goes before the branch does', () => {
  assert.equal(text(composeRow1(ROW1, 25)), '⑂ chore/x +2 ~1')
})

test('row 1: the branch is never shortened', () => {
  const long = { ...ROW1, worktree: undefined, branch: 'feat/dev-1807-a-very-long-branch-name' }
  assert.ok(text(composeRow1(long, 10)).includes('feat/dev-1807-a-very-long-branch-name'))
})

test('row 1: home itself is ~', () => {
  assert.equal(text(composeRow1({ cwd: '/Users/me', home: '/Users/me', staged: 0, modified: 0 }, 80)), '~')
})

test('bar: ten cells, floored', () => {
  assert.equal(bar(37), '▓▓▓░░░░░░░')
  assert.equal(bar(0), '░░░░░░░░░░')
  assert.equal(bar(150), '▓▓▓▓▓▓▓▓▓▓')
})

test('formatCountdown', () => {
  assert.equal(formatCountdown(5 * 60_000), '5m')
  assert.equal(formatCountdown(72 * 60_000), '1h12')
  assert.equal(formatCountdown(65 * 60_000), '1h05')
  assert.equal(formatCountdown((3 * 24 + 2) * 3_600_000), '3j')
  assert.equal(formatCountdown(-1), '0m')
})

const ROW2: Row2Input = {
  model: 'Opus 5.5 (1M)', effort: 'high', contextPct: 37, contextLevel: 'ok',
  limits: [
    { label: '5h', percent: 24, level: 'ok', countdown: '1h12' },
    { label: '7d', percent: 41, level: 'warning', countdown: '3j' },
  ],
}
const FULL2 = 'Opus 5.5 (1M) · high  ▓▓▓░░░░░░░ 37%  5h 24% ↻1h12  7d 41% ↻3j'

test('row 2: everything fits', () => {
  assert.equal(text(composeRow2(ROW2, 100)), FULL2)
})

test('row 2: countdowns are shed first', () => {
  const t = text(composeRow2(ROW2, [...FULL2].length - 1))
  assert.ok(!t.includes('↻'))
  assert.ok(t.includes('7d 41%'))
})

test('row 2: never wider than the band, at any width', () => {
  for (let cols = 1; cols <= 120; cols++) {
    assert.ok(width(composeRow2(ROW2, cols)) <= cols, `cols=${cols}: "${text(composeRow2(ROW2, cols))}"`)
  }
})

test('row 2: shedding order is countdowns, 7d, 5h, effort, bar', () => {
  for (let cols = 1; cols <= 120; cols++) {
    const t = text(composeRow2(ROW2, cols))
    if (t.includes('↻')) assert.ok(t.includes('7d'), `cols=${cols}`)
    if (t.includes('7d')) assert.ok(t.includes('5h'), `cols=${cols}`)
    if (t.includes('5h')) assert.ok(t.includes('high'), `cols=${cols}`)
    if (t.includes('high')) assert.ok(t.includes('▓'), `cols=${cols}`)
  }
})

test('row 2: the context level colours both bar and percent', () => {
  const row = composeRow2({ ...ROW2, contextLevel: 'danger' }, 100)
  assert.equal(row.find((s) => s.text.startsWith('▓'))?.tone, 'danger')
  assert.equal(row.find((s) => s.text === '37%')?.tone, 'danger')
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/usage-band/tests/layout.spec.ts`
Expected: FAIL, `Cannot find module '…/hooks/layout.ts'`.

- [ ] **Step 3: Write `layout.ts`**

This is a port of the row-building half of `claude/.claude/statusline-command.sh`:

```ts
// Builds the band's two rows as tone-tagged segments. A port of the
// row-building half of claude/.claude/statusline-command.sh; register.ts maps
// tones to theme colours. Widths count code points, which the glyphs here
// (… ⑂ ⌂ ▓ ░ ↻) need.

import type { Level } from './pace.ts'

export type Tone =
  | Level | 'path' | 'worktree' | 'branch' | 'model' | 'dim' | 'staged' | 'modified' | 'plain'
export type Segment = { text: string; tone: Tone }
export type Row = Segment[]

const SEP = '  '
const len = (s: string) => [...s].length

export const width = (row: Row): number => row.reduce((n, s) => n + len(s.text), 0)

// Fit a path into max columns, escalating only as far as needed.
export function shortenPath(p: string, max: number): string {
  const m = Math.max(max, 8)
  if (len(p) <= m) return p
  const parts = p.split('/')
  const n = parts.length
  // 1. Elide the middle, keeping the head and as many trailing parts as fit.
  for (let keep = n - 1; keep >= 1; keep--) {
    const cand = [parts[0], '…', ...parts.slice(n - keep)].join('/')
    if (len(cand) <= m) return cand
  }
  // 2. Abbreviate every intermediate component to one character.
  const abbrev = [parts[0], ...parts.slice(1, n - 1).map((s) => [...s][0] ?? ''), parts[n - 1]].join('/')
  if (len(abbrev) <= m) return abbrev
  // 3. Give up and clip the head.
  return '…' + [...p].slice(-(m - 1)).join('')
}

function joinParts(parts: Row[]): Row {
  const out: Row = []
  parts.forEach((p, k) => {
    if (k > 0) out.push({ text: SEP, tone: 'plain' })
    out.push(...p)
  })
  return out
}

export type Row1Input = {
  cwd: string
  home: string
  worktree?: string
  branch?: string
  staged: number
  modified: number
}

// The path is the only elastic part: under 10 columns it is dropped outright.
// When chip and branch cannot both fit, the chip goes; the branch never does.
export function composeRow1(i: Row1Input, cols: number): Row {
  const shortCwd =
    i.cwd === i.home ? '~' : i.cwd.startsWith(i.home + '/') ? '~' + i.cwd.slice(i.home.length) : i.cwd
  const dirty: Row = []
  if (i.staged > 0) dirty.push({ text: ` +${i.staged}`, tone: 'staged' })
  if (i.modified > 0) dirty.push({ text: ` ~${i.modified}`, tone: 'modified' })

  const build = (withWorktree: boolean): Row => {
    const parts: Row[] = []
    if (withWorktree && i.worktree) parts.push([{ text: `⌂ ${i.worktree}`, tone: 'worktree' }])
    if (i.branch) parts.push([{ text: `⑂ ${i.branch}`, tone: 'branch' }, ...dirty])
    const avail = cols - parts.reduce((n, p) => n + SEP.length + width(p), 0)
    if (avail >= 10 || parts.length === 0) {
      parts.unshift([{ text: shortenPath(shortCwd, Math.max(avail, 1)), tone: 'path' }])
    }
    return joinParts(parts)
  }

  const full = build(true)
  return width(full) > cols && i.worktree ? build(false) : full
}

export function bar(pct: number): string {
  const w = 10
  const f = Math.max(0, Math.min(w, Math.floor((pct * w) / 100)))
  return '▓'.repeat(f) + '░'.repeat(w - f)
}

export function formatCountdown(ms: number): string {
  const min = Math.max(0, Math.floor(ms / 60_000))
  if (min < 60) return `${min}m`
  const h = Math.floor(min / 60)
  if (h < 24) return `${h}h${String(min % 60).padStart(2, '0')}`
  return `${Math.floor(h / 24)}j`
}

export type Limit = { label: '5h' | '7d'; percent: number; level: Level; countdown?: string }

export type Row2Input = {
  model: string
  effort?: string
  contextPct?: number
  contextLevel: Level
  limits: Limit[]
}

type Want = { countdown: boolean; d7: boolean; h5: boolean; effort: boolean; bar: boolean }

// Shed right-to-left until it fits: countdowns, 7d, 5h, effort, then the bar.
const SHED: Want[] = [
  { countdown: true, d7: true, h5: true, effort: true, bar: true },
  { countdown: false, d7: true, h5: true, effort: true, bar: true },
  { countdown: false, d7: false, h5: true, effort: true, bar: true },
  { countdown: false, d7: false, h5: false, effort: true, bar: true },
  { countdown: false, d7: false, h5: false, effort: false, bar: true },
  { countdown: false, d7: false, h5: false, effort: false, bar: false },
]

function compose(i: Row2Input, w: Want): Row {
  const row: Row = [{ text: i.model, tone: 'model' }]
  if (w.effort && i.effort) row.push({ text: ` · ${i.effort}`, tone: 'dim' })
  if (i.contextPct !== undefined) {
    const pct = Math.round(i.contextPct)
    row.push({ text: SEP, tone: 'plain' })
    if (w.bar) row.push({ text: bar(pct), tone: i.contextLevel }, { text: ' ', tone: 'plain' })
    row.push({ text: `${pct}%`, tone: i.contextLevel })
  }
  for (const l of i.limits) {
    if (!(l.label === '5h' ? w.h5 : w.d7)) continue
    row.push(
      { text: SEP, tone: 'plain' },
      { text: `${l.label} `, tone: 'dim' },
      { text: `${Math.round(l.percent)}%`, tone: l.level },
    )
    if (w.countdown && l.countdown) row.push({ text: ` ↻${l.countdown}`, tone: 'dim' })
  }
  return row
}

export function composeRow2(i: Row2Input, cols: number): Row {
  for (const w of SHED) {
    const row = compose(i, w)
    if (width(row) <= cols) return row
  }
  return [{ text: [...i.model].slice(0, Math.max(0, cols)).join(''), tone: 'model' }]
}
```

- [ ] **Step 4: Run the test to verify that it passes**

Run: `node --test claude-mods/usage-band/tests/layout.spec.ts`
Expected: PASS, 15 tests. If `row 1: the worktree chip goes…` fails, recompute
by hand. The protected width at 25 columns is
`2+17 + 2+9+3+3 = 36`, so the path is dropped and the first build is 34 wide.
The second build is `⑂ chore/x +2 ~1`, 15 wide.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/usage-band/hooks/layout.ts claude-mods/usage-band/tests/layout.spec.ts
git commit -m "feat(claude-mods): band rows, path shortening and shedding

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: `git.ts`: parse status and worktree

**Files:**
- Create: `claude-mods/usage-band/hooks/git.ts`
- Test: `claude-mods/usage-band/tests/git.spec.ts`

**Interfaces:**
- Produces:
  - `type GitInfo = { branch?: string; worktree?: string; staged: number; modified: number }`
  - `STATUS_ARGV: readonly string[]`
  - `REVPARSE_ARGV: readonly string[]`
  - `parseStatus(stdout: string): Omit<GitInfo, 'worktree'>`
  - `parseWorktree(stdout: string): string | undefined`

- [ ] **Step 1: Write the failing test**

`claude-mods/usage-band/tests/git.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { parseStatus, parseWorktree } from '../hooks/git.ts'

test('branch and dirty counts, untracked ignored', () => {
  const out = [
    '# branch.oid 0df6b3e1234567',
    '# branch.head main',
    '1 M. N... 100644 100644 100644 a b CLAUDE.md',
    '1 .M N... 100644 100644 100644 a b nvim/init.lua',
    '1 MM N... 100644 100644 100644 a b both.lua',
    '2 R. N... 100644 100644 100644 a b R100 new\told',
    '? untracked.txt',
  ].join('\n')
  assert.deepEqual(parseStatus(out), { branch: 'main', staged: 3, modified: 2 })
})

test('detached head shows the short oid', () => {
  assert.equal(parseStatus('# branch.oid 0df6b3e1234567\n# branch.head (detached)\n').branch, '0df6b3e')
})

test('not a repo: empty output gives no branch and zero counts', () => {
  assert.deepEqual(parseStatus(''), { branch: undefined, staged: 0, modified: 0 })
})

test('worktree: name only when git-dir differs from the common dir', () => {
  assert.equal(
    parseWorktree('/Users/me/dotfiles.tooling\n/Users/me/dotfiles/.git/worktrees/tooling\n/Users/me/dotfiles/.git\n'),
    'dotfiles.tooling',
  )
  assert.equal(parseWorktree('/Users/me/dotfiles\n/Users/me/dotfiles/.git\n/Users/me/dotfiles/.git\n'), undefined)
  assert.equal(parseWorktree(''), undefined)
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/usage-band/tests/git.spec.ts`
Expected: FAIL, `Cannot find module`.

- [ ] **Step 3: Write `git.ts`**

```ts
// Parses the two git calls the band makes. The mod runs them through
// $.process.run; parsing stays here so it is testable without a session.

export type GitInfo = { branch?: string; worktree?: string; staged: number; modified: number }

// One `status --porcelain=v2 --branch` yields branch *and* dirty counts.
export const STATUS_ARGV = ['git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch'] as const
export const REVPARSE_ARGV = [
  'git', 'rev-parse', '--path-format=absolute', '--show-toplevel', '--git-dir', '--git-common-dir',
] as const

export function parseStatus(stdout: string): Omit<GitInfo, 'worktree'> {
  let oid = ''
  let head: string | undefined
  let staged = 0
  let modified = 0
  for (const line of stdout.split('\n')) {
    if (line.startsWith('# branch.oid ')) oid = line.slice(13).slice(0, 7)
    else if (line.startsWith('# branch.head ')) head = line.slice(14)
    else if (line.startsWith('1 ') || line.startsWith('2 ')) {
      const xy = line.slice(2, 4)
      if (xy[0] !== '.') staged++
      if (xy[1] !== '.') modified++
    }
  }
  return { branch: head === '(detached)' ? oid : head, staged, modified }
}

// In a linked worktree, --git-dir points into the main repo's .git/worktrees/.
export function parseWorktree(stdout: string): string | undefined {
  const [top, gitDir, commonDir] = stdout.trim().split('\n')
  if (!top || !gitDir || !commonDir || gitDir === commonDir) return undefined
  return top.split('/').pop()
}
```

- [ ] **Step 4: Run the test to verify that it passes**

Run: `node --test claude-mods/usage-band/tests/git.spec.ts`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/usage-band/hooks/git.ts claude-mods/usage-band/tests/git.spec.ts
git commit -m "feat(claude-mods): parse git status and worktree for the band

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: `usage-band` glue: `register.ts`

**Files:**
- Modify: `claude-mods/usage-band/hooks/register.ts`, replacing the stub

**Interfaces:**
- Consumes: everything Tasks 2-4 produce, plus the mods API from the vendored
  `claude-code.d.ts`.
- Produces: `register(on: On): void`

There is no runtime test until Task 12. `tsc` is the gate, and the vendored
`.d.ts` is the source of truth. If a call below does not type-check, change the
call to match the types. Never loosen the types with `any`.

- [ ] **Step 1: Write `register.ts`**

```ts
// usage-band: the status line, redrawn as a mod in the band above the prompt.
// Usage figures are pushed by session.measure; git is polled with a 5 s cache,
// like the script this replaces; a 60 s clock keeps pace colours and
// countdowns moving between requests, since the budget grows with time alone.

import type { EngineInterface as Api, On } from 'claude-code'
import { contextLevel, paceLevel, type WindowKind } from './pace.ts'
import { composeRow1, composeRow2, formatCountdown, type Limit, type Tone } from './layout.ts'
import { parseStatus, parseWorktree, REVPARSE_ARGV, STATUS_ARGV, type GitInfo } from './git.ts'

// ANSI-16 theme slots only, so the band follows the terminal palette.
const TONE_COLOR: Record<Tone, string | undefined> = {
  ok: 'green', warning: 'yellow', danger: 'red', none: 'gray',
  path: 'blue', worktree: 'magenta', branch: 'yellow', model: 'cyan',
  dim: 'gray', staged: 'green', modified: 'red', plain: undefined,
}
const LABEL: Record<WindowKind, '5h' | '7d'> = { five_hour: '5h', seven_day: '7d' }
const GIT_TTL_MS = 5_000

type RateLimit = { kind: string; percentUsed: number; resetsAt?: string }

let contextPct: number | undefined
let limits: RateLimit[] = []
let model = ''
let effort: string | undefined
let cwd = ''
let home = ''
let git: GitInfo = { staged: 0, modified: 0 }
let gitAt = 0

export function register(on: On): void {
  const redraw = ($: Api) => $.ui.invalidate('ui.render')

  async function refreshGit($: Api, force = false): Promise<void> {
    const now = await $.clock.now()
    if (!force && now - gitAt < GIT_TTL_MS) return
    gitAt = now
    try {
      cwd = await $.session.cwd()
      const [st, rp] = await Promise.all([$.process.run(STATUS_ARGV), $.process.run(REVPARSE_ARGV)])
      git =
        st.exitCode === 0
          ? { ...parseStatus(st.stdout), worktree: rp.exitCode === 0 ? parseWorktree(rp.stdout) : undefined }
          : { staged: 0, modified: 0 }
    } catch {
      git = { staged: 0, modified: 0 }
    }
    redraw($)
  }

  on('session.start', async ($, e, next) => {
    home = (await $.env.get('HOME')) ?? ''
    cwd = await $.session.cwd()
    model = await $.session.model()
    const u = await $.session.usage()
    contextPct = u.context.percent
    limits = [...u.rateLimits]
    await refreshGit($, true)
    $.clock.every(60_000, () => redraw($))
    return next(e)
  })

  on('session.measure', async ($, e, next) => {
    contextPct = e.context.percent
    limits = [...e.rateLimits]
    model = await $.session.model()
    if (e.changed.includes('context') || e.changed.includes('rateLimits')) redraw($)
    return next(e)
  })

  // Main loop only: a subagent's step may run at another effort.
  on('turn.step', async function* ($, e, next) {
    if (e.agentId === undefined) {
      const next_ = e.effort === undefined ? undefined : String(e.effort)
      if (next_ !== effort) {
        effort = next_
        redraw($)
      }
    }
    return yield* next(e)
  })

  on('turn.complete', async ($, e, next) => {
    await refreshGit($, true)
    return next(e)
  })

  on('tool.call', { tool: ['Bash', 'Edit', 'Write'] }, async ($, e, next) => {
    const result = await next(e)
    void refreshGit($)
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const { Box, Text } = $.ui.resolve(e)
    const cols = e.props.bodyColumns
    const now = await $.clock.now()

    const shown: Limit[] = limits
      .filter((l): l is RateLimit & { kind: WindowKind } => l.kind in LABEL)
      .map((l) => ({
        label: LABEL[l.kind],
        percent: l.percentUsed,
        level: paceLevel(l.kind, l.percentUsed, l.resetsAt, now),
        countdown: l.resetsAt ? formatCountdown(Date.parse(l.resetsAt) - now) : undefined,
      }))

    const rows = [
      composeRow1({ cwd, home, ...git }, cols),
      composeRow2({ model, effort, contextPct, contextLevel: contextLevel(contextPct), limits: shown }, cols),
    ]
    const ours = rows.map((row) =>
      Text({
        wrap: 'truncate-end',
        children: row.map((s) => {
          const color = TONE_COLOR[s.tone]
          return color ? Text({ color, children: [s.text] }) : s.text
        }),
      }),
    )
    const theirs = await next(e)
    return Box({ flexDirection: 'column', children: theirs ? [...ours, theirs] : ours })
  })
}
```

- [ ] **Step 2: Type-check**

Run: `bash claude-mods/check.sh`
Expected: the specs pass and `tsc` prints nothing. Fix any type errors by
matching the vendored types. Likely spots:
- the `EngineInterface` import (the d.ts header names it as the type of `$`);
- the readonly `argv` passed to `$.process.run`;
- the `tool` matcher array.

Note each change you make in the commit body.

- [ ] **Step 3: Commit**

```bash
git add claude-mods/usage-band/hooks/register.ts
git commit -m "feat(claude-mods): wire usage-band to session.measure and the band

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: `binding.ts` + `template.ts`

**Files:**
- Create: `claude-mods/subject-todo/hooks/binding.ts`, `claude-mods/subject-todo/hooks/template.ts`
- Test: `claude-mods/subject-todo/tests/binding.spec.ts`

**Interfaces:**
- Produces:
  - `ticketFromText(text: string): string | undefined`, an upper-cased key such as `'DEV-1807'`
  - `ticketFromBranch(branch: string | undefined): string | undefined`
  - `ticketToBind(boundKey: string | undefined, text: string): string | undefined`
  - `TICKET_TEMPLATE: readonly string[]`

- [ ] **Step 1: Write the failing test**

`claude-mods/subject-todo/tests/binding.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { ticketFromBranch, ticketFromText, ticketToBind } from '../hooks/binding.ts'
import { TICKET_TEMPLATE } from '../hooks/template.ts'

test('Linear URL in a prompt', () => {
  assert.equal(ticketFromText('voici le ticket https://linear.app/sillant/issue/DEV-1807/export-csv'), 'DEV-1807')
  assert.equal(ticketFromText('https://linear.app/sillant/issue/dev-42'), 'DEV-42')
  assert.equal(ticketFromText('on parle de DEV-1807 sans lien'), undefined)
})

test('branch fallback', () => {
  assert.equal(ticketFromBranch('dev-1807-export-csv'), 'DEV-1807')
  assert.equal(ticketFromBranch('feat/dev-1807'), 'DEV-1807')
  assert.equal(ticketFromBranch('stephane/DEV-1807-x'), 'DEV-1807')
  assert.equal(ticketFromBranch('main'), undefined)
  assert.equal(ticketFromBranch('devops-12'), undefined)
  assert.equal(ticketFromBranch(undefined), undefined)
})

test('a bound session is never rebound by a later link', () => {
  const link = 'https://linear.app/sillant/issue/DEV-2000/other'
  assert.equal(ticketToBind(undefined, link), 'DEV-2000')
  assert.equal(ticketToBind('DEV-1807', link), undefined)
  assert.equal(ticketToBind('conv:abc', link), undefined)
})

test('ticket template has the 11 steps, in order', () => {
  assert.equal(TICKET_TEMPLATE.length, 11)
  assert.equal(TICKET_TEMPLATE[0], 'Lire le ticket et comprendre le sujet')
  assert.equal(TICKET_TEMPLATE[9], 'Merge')
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/subject-todo/tests/binding.spec.ts`
Expected: FAIL, `Cannot find module`.

- [ ] **Step 3: Write both files**

`claude-mods/subject-todo/hooks/binding.ts`:
```ts
// Which ticket a session is about. A Linear link in a prompt wins; a dev-<n>
// branch is the fallback. Keys are upper-cased so DEV-1807 is one subject
// whatever the spelling.

const LINEAR_URL = /linear\.app\/[\w-]+\/issue\/([a-z]+-\d+)/i
const DEV_BRANCH = /(?:^|[/_-])(dev-\d+)(?=$|[/_-])/i

export function ticketFromText(text: string): string | undefined {
  return LINEAR_URL.exec(text)?.[1]?.toUpperCase()
}

export function ticketFromBranch(branch: string | undefined): string | undefined {
  return branch ? DEV_BRANCH.exec(branch)?.[1]?.toUpperCase() : undefined
}

// Only an unbound session binds from a prompt: a second link pasted later is
// a reference, not a change of subject.
export function ticketToBind(boundKey: string | undefined, text: string): string | undefined {
  return boundKey === undefined ? ticketFromText(text) : undefined
}
```

`claude-mods/subject-todo/hooks/template.ts`:
```ts
// The default list for a ticket. Claude adapts it per ticket with the
// subject_todo tool (`replace`); edit here to change the workflow itself.
export const TICKET_TEMPLATE: readonly string[] = [
  'Lire le ticket et comprendre le sujet',
  'Écrire la fiche de cadrage',
  'Relire la fiche de cadrage et la corriger si nécessaire',
  '1ère implémentation',
  'Préparer la QA de dev manuelle',
  'Faire la QA de dev',
  'Corriger les retours de QA',
  'Ouvrir les PRs en ready-to-review',
  'Adresser les commentaires de PRs',
  'Merge',
  'Nettoyer : worktrees, fiche doc, branches git, etc.',
]
```

- [ ] **Step 4: Run the test to verify that it passes**

Run: `node --test claude-mods/subject-todo/tests/binding.spec.ts`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/subject-todo/hooks/binding.ts claude-mods/subject-todo/hooks/template.ts claude-mods/subject-todo/tests/binding.spec.ts
git commit -m "feat(claude-mods): bind subjects from Linear links and dev branches

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: `subject.ts`: model, tool actions, Claude context

**Files:**
- Create: `claude-mods/subject-todo/hooks/subject.ts`
- Test: `claude-mods/subject-todo/tests/subject.spec.ts`

**Interfaces:**
- Produces:
  - `type Status = 'todo' | 'doing' | 'done' | 'skipped'`
  - `type Actor = 'claude' | 'user'`
  - `type Item = { id: string; text: string; status: Status; by: Actor; changedAt: string }`
  - `type Subject = { key: string; kind: 'ticket' | 'conversation'; title: string; items: Item[]; updatedAt: string }`
  - `type ToolAction = { action: 'bind'; title: string } | { action: 'replace'; items: { text: string; status?: Status }[] } | { action: 'update'; id: string; status?: Status; text?: string } | { action: 'add'; text: string; after?: string }`
  - `type Outcome = { subject: Subject } | { error: string }`
  - `GLYPH: Record<Status, string>`
  - `STATUS_CYCLE: Record<Status, Status>`
  - `createSubject(key, kind, title, texts: readonly string[], now: string, rand?: () => number): Subject`
  - `progress(s: Subject): { done: number; total: number }`
  - `cycleItem(s: Subject, id: string, now: string): Outcome`
  - `applyAction(s: Subject, a: ToolAction, actor: Actor, now: string, rand?: () => number): Outcome`
  - `renderList(s: Subject): string`
  - `contextFor(s: Subject, opts: { since?: string; full: boolean }): string`

- [ ] **Step 1: Write the failing test**

`claude-mods/subject-todo/tests/subject.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  applyAction, contextFor, createSubject, cycleItem, progress, renderList, type Outcome, type Subject,
} from '../hooks/subject.ts'

const T0 = '2026-10-07T10:00:00.000Z'
const T1 = '2026-10-07T11:00:00.000Z'
const T2 = '2026-10-07T12:00:00.000Z'

// Deterministic ids: a, b, c, ... from a counter-driven rand.
function seq() {
  let n = 0
  return () => (n++ * 1) / 46656 + 1e-9
}
const ok = (o: Outcome): Subject => {
  if ('error' in o) throw new Error(o.error)
  return o.subject
}
const base = () => createSubject('DEV-1807', 'ticket', 'DEV-1807', ['Lire', 'Cadrer', 'Coder'], T0, seq())

test('createSubject: todo items with unique ids, by claude', () => {
  const s = base()
  assert.equal(s.items.length, 3)
  assert.equal(new Set(s.items.map((i) => i.id)).size, 3)
  assert.ok(s.items.every((i) => i.status === 'todo' && i.by === 'claude'))
})

test('progress: skipped counts in neither done nor total', () => {
  let s = base()
  s = ok(applyAction(s, { action: 'update', id: s.items[0].id, status: 'done' }, 'claude', T1))
  s = ok(applyAction(s, { action: 'update', id: s.items[1].id, status: 'skipped' }, 'claude', T1))
  assert.deepEqual(progress(s), { done: 1, total: 2 })
})

test('cycleItem: todo → doing → done → skipped → todo, marked by user', () => {
  let s = base()
  const id = s.items[0].id
  const seen: string[] = []
  for (let k = 0; k < 4; k++) {
    s = ok(cycleItem(s, id, T1))
    seen.push(s.items[0].status)
  }
  assert.deepEqual(seen, ['doing', 'done', 'skipped', 'todo'])
  assert.equal(s.items[0].by, 'user')
  assert.equal(s.items[0].changedAt, T1)
})

test('update: unknown id is an error that names the id', () => {
  const o = applyAction(base(), { action: 'update', id: 'zzz', status: 'done' }, 'claude', T1)
  assert.ok('error' in o && o.error.includes('zzz'))
})

test('add: appends, or inserts after an id', () => {
  let s = base()
  s = ok(applyAction(s, { action: 'add', text: 'PR vicat' }, 'claude', T1, seq()))
  assert.equal(s.items.at(-1)?.text, 'PR vicat')
  s = ok(applyAction(s, { action: 'add', text: 'Relire', after: s.items[0].id }, 'user', T1, seq()))
  assert.equal(s.items[1].text, 'Relire')
  assert.equal(s.items[1].by, 'user')
})

test('replace: keeps ids of items whose text is unchanged', () => {
  const s = base()
  const lireId = s.items[0].id
  const r = ok(applyAction(s, { action: 'replace', items: [{ text: 'Lire', status: 'done' }, { text: 'Nouveau' }] }, 'claude', T1, seq()))
  assert.equal(r.items[0].id, lireId)
  assert.equal(r.items[0].status, 'done')
  assert.equal(r.items[1].status, 'todo')
  assert.equal(r.items.length, 2)
})

test('bind on a bound subject renames it', () => {
  const r = ok(applyAction(base(), { action: 'bind', title: 'Export CSV des prix' }, 'claude', T1))
  assert.equal(r.title, 'Export CSV des prix')
})

test('renderList: header with progress, one line per item with id and glyph', () => {
  const s = ok(applyAction(base(), { action: 'update', id: base().items[0].id, status: 'done' }, 'claude', T1))
  const lines = renderList(s).split('\n')
  assert.equal(lines[0], 'DEV-1807 · DEV-1807 (1/3)')
  assert.equal(lines[1], `[${s.items[0].id}] ✓ Lire`)
  assert.equal(lines.length, 4)
})

test('contextFor: short form names progress and what is in progress', () => {
  let s = base()
  s = ok(applyAction(s, { action: 'update', id: s.items[2].id, status: 'doing' }, 'claude', T1))
  const c = contextFor(s, { full: false })
  assert.ok(c.includes('(0/3)'))
  assert.ok(c.includes('En cours : Coder'))
  assert.ok(!c.includes('[')) // no list in the short form
})

test('contextFor: reports pane changes since the last prompt only', () => {
  let s = base()
  s = ok(cycleItem(s, s.items[0].id, T1))
  s = ok(cycleItem(s, s.items[1].id, T2))
  const changed = contextFor(s, { since: T1, full: false }).split('\n').find((l) => l.startsWith('Changé')) ?? ''
  assert.ok(changed.includes('Cadrer'))
  assert.ok(!changed.includes('Lire'))
})

test('contextFor: full form includes the list and asks to adapt an untouched ticket', () => {
  const c = contextFor(base(), { full: true })
  assert.ok(c.includes('[') && c.includes('○ Lire'))
  assert.ok(c.includes('replace'))
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/subject-todo/tests/subject.spec.ts`
Expected: FAIL, `Cannot find module`.

- [ ] **Step 3: Write `subject.ts`**

```ts
// The subject and its items, and every change Claude or the user can make.
// Pure: every function returns a new Subject (or an error) and takes `now`
// as an argument, so the specs control time.

export type Status = 'todo' | 'doing' | 'done' | 'skipped'
export type Actor = 'claude' | 'user'
export type Item = { id: string; text: string; status: Status; by: Actor; changedAt: string }
export type Subject = {
  key: string
  kind: 'ticket' | 'conversation'
  title: string
  items: Item[]
  updatedAt: string
}
export type ToolAction =
  | { action: 'bind'; title: string }
  | { action: 'replace'; items: { text: string; status?: Status }[] }
  | { action: 'update'; id: string; status?: Status; text?: string }
  | { action: 'add'; text: string; after?: string }
export type Outcome = { subject: Subject } | { error: string }

export const GLYPH: Record<Status, string> = { todo: '○', doing: '▶', done: '✓', skipped: '–' }
export const STATUS_CYCLE: Record<Status, Status> = { todo: 'doing', doing: 'done', done: 'skipped', skipped: 'todo' }

// Three base-36 characters: short enough for Claude to quote, unique per subject.
function newId(taken: ReadonlySet<string>, rand: () => number): string {
  for (;;) {
    const id = Math.floor(rand() * 46656).toString(36).padStart(3, '0')
    if (!taken.has(id)) return id
  }
}

function makeItems(texts: readonly { text: string; status?: Status; id?: string }[], actor: Actor, now: string, rand: () => number, taken = new Set<string>()): Item[] {
  return texts.map((t) => {
    const id = t.id ?? newId(taken, rand)
    taken.add(id)
    return { id, text: t.text, status: t.status ?? 'todo', by: actor, changedAt: now }
  })
}

export function createSubject(
  key: string,
  kind: Subject['kind'],
  title: string,
  texts: readonly string[],
  now: string,
  rand: () => number = Math.random,
): Subject {
  return { key, kind, title, items: makeItems(texts.map((text) => ({ text })), 'claude', now, rand), updatedAt: now }
}

export function progress(s: Subject): { done: number; total: number } {
  const counted = s.items.filter((i) => i.status !== 'skipped')
  return { done: counted.filter((i) => i.status === 'done').length, total: counted.length }
}

const unknownId = (id: string): Outcome => ({ error: `Aucun item avec l'id "${id}".` })

function edit(s: Subject, id: string, patch: Partial<Pick<Item, 'status' | 'text'>>, actor: Actor, now: string): Outcome {
  if (!s.items.some((i) => i.id === id)) return unknownId(id)
  const items = s.items.map((i) => (i.id === id ? { ...i, ...patch, by: actor, changedAt: now } : i))
  return { subject: { ...s, items, updatedAt: now } }
}

export function cycleItem(s: Subject, id: string, now: string): Outcome {
  const item = s.items.find((i) => i.id === id)
  return item ? edit(s, id, { status: STATUS_CYCLE[item.status] }, 'user', now) : unknownId(id)
}

export function applyAction(s: Subject, a: ToolAction, actor: Actor, now: string, rand: () => number = Math.random): Outcome {
  switch (a.action) {
    case 'bind':
      return { subject: { ...s, title: a.title, updatedAt: now } }
    case 'update': {
      const patch: Partial<Pick<Item, 'status' | 'text'>> = {}
      if (a.status) patch.status = a.status
      if (a.text) patch.text = a.text
      return edit(s, a.id, patch, actor, now)
    }
    case 'add': {
      const [item] = makeItems([{ text: a.text }], actor, now, rand, new Set(s.items.map((i) => i.id)))
      if (a.after === undefined) return { subject: { ...s, items: [...s.items, item], updatedAt: now } }
      const at = s.items.findIndex((i) => i.id === a.after)
      if (at < 0) return unknownId(a.after)
      const items = [...s.items.slice(0, at + 1), item, ...s.items.slice(at + 1)]
      return { subject: { ...s, items, updatedAt: now } }
    }
    case 'replace': {
      // Reuse the id of an existing item with the same text, so ids Claude
      // already holds stay valid across an adaptation.
      const byText = new Map(s.items.map((i) => [i.text, i.id]))
      const wanted = a.items.map((t) => ({ ...t, id: byText.get(t.text) }))
      const taken = new Set(wanted.flatMap((t) => (t.id ? [t.id] : [])))
      return { subject: { ...s, items: makeItems(wanted, actor, now, rand, taken), updatedAt: now } }
    }
  }
}

export function renderList(s: Subject): string {
  const { done, total } = progress(s)
  const header = s.kind === 'ticket' ? `${s.key} · ${s.title} (${done}/${total})` : `${s.title} (${done}/${total})`
  return [header, ...s.items.map((i) => `[${i.id}] ${GLYPH[i.status]} ${i.text}`)].join('\n')
}

// What Claude reads beside each prompt. Short by default; `full` adds the list
// with ids (first prompt after a bind or a resume) and, for an untouched
// ticket, asks Claude to adapt the template.
export function contextFor(s: Subject, opts: { since?: string; full: boolean }): string {
  const { done, total } = progress(s)
  const name = s.kind === 'ticket' ? `Sujet ${s.key} : ${s.title}` : `Sujet : ${s.title}`
  const lines = [`${name} (${done}/${total}).`]
  const doing = s.items.filter((i) => i.status === 'doing').map((i) => i.text)
  if (doing.length > 0) lines.push(`En cours : ${doing.join(', ')}.`)
  const since = opts.since
  const byUser = since === undefined ? [] : s.items.filter((i) => i.by === 'user' && i.changedAt > since)
  if (byUser.length > 0) {
    lines.push(`Changé par l'utilisateur depuis le panneau : ${byUser.map((i) => `${i.text} (${i.status})`).join(', ')}.`)
  }
  lines.push("Tiens la liste à jour avec l'outil subject_todo (update, add, replace) au fil du travail.")
  if (opts.full) {
    const untouched = s.kind === 'ticket' && s.items.every((i) => i.status === 'todo' && i.by === 'claude')
    if (untouched) {
      lines.push("C'est le modèle par défaut : adapte-le à ce ticket avec replace (passe en skipped ce qui ne s'applique pas, ajoute ce qui manque).")
    }
    lines.push('', renderList(s))
  }
  return lines.join('\n')
}
```

- [ ] **Step 4: Run the test to verify that it passes**

Run: `node --test claude-mods/subject-todo/tests/subject.spec.ts`
Expected: PASS, 11 tests. The `seq()` helper yields distinct ids, because each
call advances by one id slot.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/subject-todo/hooks/subject.ts claude-mods/subject-todo/tests/subject.spec.ts
git commit -m "feat(claude-mods): subject model, tool actions and Claude context

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: `store.ts`: `$.store` adapter

**Files:**
- Create: `claude-mods/subject-todo/hooks/store.ts`
- Test: `claude-mods/subject-todo/tests/store.spec.ts`

**Interfaces:**
- Consumes: `Subject`, `Outcome` from `./subject.ts`
- Produces:
  - `interface KV { get(key: string): Promise<unknown>; set(key: string, value: unknown): Promise<void>; delete(key: string): Promise<void>; keys(): Promise<string[]> }`.
    It matches `$.store` exactly.
  - `loadSubject(kv: KV, key: string): Promise<Subject | undefined>`
  - `saveSubject(kv: KV, s: Subject): Promise<void>`
  - `mutateSubject(kv: KV, key: string, fn: (s: Subject) => Outcome): Promise<Outcome>`
  - `bindSession(kv: KV, sessionId: string, key: string): Promise<void>`
  - `boundKey(kv: KV, sessionId: string): Promise<string | undefined>`
  - `prune(kv: KV, now: number, maxAgeMs?: number): Promise<number>`

- [ ] **Step 1: Write the failing test**

`claude-mods/subject-todo/tests/store.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { bindSession, boundKey, loadSubject, mutateSubject, prune, saveSubject, type KV } from '../hooks/store.ts'
import { applyAction, createSubject, type Subject } from '../hooks/subject.ts'

function memoryKV(): KV & { map: Map<string, unknown> } {
  const map = new Map<string, unknown>()
  return {
    map,
    get: async (k) => structuredClone(map.get(k)),
    set: async (k, v) => void map.set(k, structuredClone(v)),
    delete: async (k) => void map.delete(k),
    keys: async () => [...map.keys()],
  }
}
const NOW = '2026-10-07T12:00:00.000Z'
const ticket = () => createSubject('DEV-1807', 'ticket', 'DEV-1807', ['Lire'], NOW)

test('round trip', async () => {
  const kv = memoryKV()
  await saveSubject(kv, ticket())
  assert.equal((await loadSubject(kv, 'DEV-1807'))?.items[0].text, 'Lire')
})

test('a corrupt or foreign value reads as no subject', async () => {
  const kv = memoryKV()
  kv.map.set('subject:DEV-1', 'oops')
  kv.map.set('subject:DEV-2', { key: 'DEV-2' })
  assert.equal(await loadSubject(kv, 'DEV-1'), undefined)
  assert.equal(await loadSubject(kv, 'DEV-2'), undefined)
})

test('mutate re-reads, so another session’s write survives', async () => {
  const kv = memoryKV()
  await saveSubject(kv, ticket())
  const stale = (await loadSubject(kv, 'DEV-1807')) as Subject // what this session loaded earlier
  // Another session adds an item in the meantime.
  await mutateSubject(kv, 'DEV-1807', (s) => applyAction(s, { action: 'add', text: 'Autre session' }, 'claude', NOW))
  // This session now ticks its first item.
  const out = await mutateSubject(kv, 'DEV-1807', (s) => applyAction(s, { action: 'update', id: stale.items[0].id, status: 'done' }, 'claude', NOW))
  assert.ok(!('error' in out))
  const final = (await loadSubject(kv, 'DEV-1807')) as Subject
  assert.deepEqual(final.items.map((i) => i.text), ['Lire', 'Autre session'])
})

test('mutate on a missing subject is an error and writes nothing', async () => {
  const kv = memoryKV()
  const out = await mutateSubject(kv, 'DEV-9', (s) => ({ subject: s }))
  assert.ok('error' in out)
  assert.equal(kv.map.size, 0)
})

test('session binding', async () => {
  const kv = memoryKV()
  await bindSession(kv, 'sess-1', 'DEV-1807')
  assert.equal(await boundKey(kv, 'sess-1'), 'DEV-1807')
  assert.equal(await boundKey(kv, 'sess-2'), undefined)
})

test('prune: old conversations and dangling bindings go, tickets stay', async () => {
  const kv = memoryKV()
  const old = '2026-08-01T00:00:00.000Z'
  await saveSubject(kv, createSubject('conv:old', 'conversation', 'vieux', [], old))
  await saveSubject(kv, createSubject('conv:new', 'conversation', 'récent', [], NOW))
  await saveSubject(kv, createSubject('DEV-1', 'ticket', 'DEV-1', [], old))
  await bindSession(kv, 'a', 'conv:old')
  await bindSession(kv, 'b', 'conv:new')
  const removed = await prune(kv, Date.parse(NOW))
  assert.equal(removed, 2)
  assert.deepEqual((await kv.keys()).sort(), ['session:b', 'subject:DEV-1', 'subject:conv:new'])
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/subject-todo/tests/store.spec.ts`
Expected: FAIL, `Cannot find module`.

- [ ] **Step 3: Write `store.ts`**

```ts
// Subjects and session bindings in $.store, which every session on the machine
// shares. get-then-set is not atomic, so every change re-reads the subject
// right before writing it, and each subject has its own key.

import type { Outcome, Subject } from './subject.ts'

export interface KV {
  get(key: string): Promise<unknown>
  set(key: string, value: unknown): Promise<void>
  delete(key: string): Promise<void>
  keys(): Promise<string[]>
}

const SUBJECT = 'subject:'
const SESSION = 'session:'
const DAY_MS = 86_400_000

function isSubject(v: unknown): v is Subject {
  if (typeof v !== 'object' || v === null) return false
  const s = v as Record<string, unknown>
  return typeof s.key === 'string' && typeof s.title === 'string' && typeof s.updatedAt === 'string' && Array.isArray(s.items)
}

export async function loadSubject(kv: KV, key: string): Promise<Subject | undefined> {
  const v = await kv.get(SUBJECT + key)
  return isSubject(v) ? v : undefined
}

export async function saveSubject(kv: KV, s: Subject): Promise<void> {
  await kv.set(SUBJECT + s.key, s)
}

export async function mutateSubject(kv: KV, key: string, fn: (s: Subject) => Outcome): Promise<Outcome> {
  const fresh = await loadSubject(kv, key)
  if (!fresh) return { error: `Le sujet ${key} est introuvable.` }
  const out = fn(fresh)
  if ('subject' in out) await saveSubject(kv, out.subject)
  return out
}

export async function bindSession(kv: KV, sessionId: string, key: string): Promise<void> {
  await kv.set(SESSION + sessionId, key)
}

export async function boundKey(kv: KV, sessionId: string): Promise<string | undefined> {
  const v = await kv.get(SESSION + sessionId)
  return typeof v === 'string' ? v : undefined
}

// Conversation subjects untouched for maxAgeMs go, then every binding whose
// subject no longer exists. Ticket subjects are kept. Returns how many keys went.
export async function prune(kv: KV, now: number, maxAgeMs = 30 * DAY_MS): Promise<number> {
  let removed = 0
  const keys = await kv.keys()
  const live = new Set<string>()
  for (const k of keys.filter((k) => k.startsWith(SUBJECT))) {
    const s = await kv.get(k)
    const stale = isSubject(s) && s.kind === 'conversation' && now - Date.parse(s.updatedAt) > maxAgeMs
    if (stale) {
      await kv.delete(k)
      removed++
    } else live.add(k.slice(SUBJECT.length))
  }
  for (const k of keys.filter((k) => k.startsWith(SESSION))) {
    const target = await kv.get(k)
    if (typeof target !== 'string' || !live.has(target)) {
      await kv.delete(k)
      removed++
    }
  }
  return removed
}
```

- [ ] **Step 4: Run the test to verify that it passes**

Run: `node --test claude-mods/subject-todo/tests/store.spec.ts`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/subject-todo/hooks/store.ts claude-mods/subject-todo/tests/store.spec.ts
git commit -m "feat(claude-mods): per-subject keys in \$.store with re-read and pruning

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: `pane.ts`: the pane tree

**Files:**
- Create: `claude-mods/subject-todo/hooks/pane.ts`
- Test: `claude-mods/subject-todo/tests/pane.spec.ts`

**Interfaces:**
- Consumes: `Subject`, `GLYPH`, `progress` from `./subject.ts`
- Produces:
  - `type Elements = { Box: Factory; Text: Factory; Button: Factory; Input: Factory }`,
    where `type Factory = (props: Record<string, unknown>) => unknown`
  - `type PaneHandlers = { onCycle(id: string): void; onAdd(text: string): void }`
  - `paneTree(el: Elements, s: Subject | undefined, h: PaneHandlers): unknown`

- [ ] **Step 1: Write the failing test**

`claude-mods/subject-todo/tests/pane.spec.ts`:
```ts
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { paneTree, type Elements } from '../hooks/pane.ts'
import { applyAction, createSubject, type Subject } from '../hooks/subject.ts'

type Node = { type: string; props: Record<string, any> }
const el: Elements = {
  Box: (props) => ({ type: 'Box', props }),
  Text: (props) => ({ type: 'Text', props }),
  Button: (props) => ({ type: 'Button', props }),
  Input: (props) => ({ type: 'Input', props }),
}
function walk(n: unknown, out: Node[] = []): Node[] {
  if (n && typeof n === 'object' && 'type' in n) {
    out.push(n as Node)
    for (const c of ((n as Node).props.children ?? []) as unknown[]) walk(c, out)
  }
  return out
}
const textOf = (nodes: Node[]) => nodes.filter((n) => n.type === 'Text').flatMap((n) => n.props.children).filter((c) => typeof c === 'string').join('|')
const NOW = '2026-10-07T12:00:00.000Z'

function subject(): Subject {
  let s = createSubject('DEV-1807', 'ticket', 'Export CSV', ['Lire', 'Cadrer', 'QA'], NOW)
  const done = applyAction(s, { action: 'update', id: s.items[0].id, status: 'done' }, 'claude', NOW)
  if ('subject' in done) s = done.subject
  const skip = applyAction(s, { action: 'update', id: s.items[2].id, status: 'skipped' }, 'claude', NOW)
  if ('subject' in skip) s = skip.subject
  return s
}

test('unbound: says how to bind, no controls', () => {
  const nodes = walk(paneTree(el, undefined, { onCycle() {}, onAdd() {} }))
  assert.ok(textOf(nodes).includes('Aucun sujet'))
  assert.ok(!nodes.some((n) => n.type === 'Button' || n.type === 'Input'))
})

test('header shows key, title and done/total', () => {
  const t = textOf(walk(paneTree(el, subject(), { onCycle() {}, onAdd() {} })))
  assert.ok(t.includes('DEV-1807 · Export CSV'))
  assert.ok(t.includes('1/2'))
})

test('one keyed button per item; pressing cycles that item', () => {
  const s = subject()
  const pressed: string[] = []
  const nodes = walk(paneTree(el, s, { onCycle: (id) => pressed.push(id), onAdd() {} }))
  const buttons = nodes.filter((n) => n.type === 'Button')
  assert.deepEqual(buttons.map((b) => b.props.key), s.items.map((i) => `item-${i.id}`))
  buttons[1].props.onPress({ surface: 'terminal' })
  assert.deepEqual(pressed, [s.items[1].id])
})

test('glyph colours and dimmed skipped items', () => {
  const nodes = walk(paneTree(el, subject(), { onCycle() {}, onAdd() {} }))
  const glyph = (g: string) => nodes.find((n) => n.type === 'Text' && n.props.children?.[0] === g)
  assert.equal(glyph('✓')?.props.color, 'green')
  assert.equal(nodes.find((n) => n.type === 'Button' && n.props.label === 'QA')?.props.dimColor, true)
})

test('the input adds trimmed text and ignores blanks', () => {
  const added: string[] = []
  const nodes = walk(paneTree(el, subject(), { onCycle() {}, onAdd: (t) => added.push(t) }))
  const input = nodes.find((n) => n.type === 'Input')!
  assert.equal(input.props.key, 'add')
  input.props.onSubmit('   ')
  input.props.onSubmit('  PR vicat ')
  assert.deepEqual(added, ['PR vicat'])
})
```

- [ ] **Step 2: Run the test to verify that it fails**

Run: `node --test claude-mods/subject-todo/tests/pane.spec.ts`
Expected: FAIL, `Cannot find module`.

- [ ] **Step 3: Write `pane.ts`**

```ts
// The pane's element tree. Takes the element factories from $.ui.resolve(e)
// as an argument, so the specs can draw it with fakes and press its buttons.

import { GLYPH, progress, type Status, type Subject } from './subject.ts'

type Factory = (props: Record<string, unknown>) => unknown
export type Elements = { Box: Factory; Text: Factory; Button: Factory; Input: Factory }
export type PaneHandlers = { onCycle(id: string): void; onAdd(text: string): void }

// Theme slots only. Button takes no colour, so the glyph is a Text beside it.
const GLYPH_COLOR: Record<Status, string | undefined> = {
  todo: undefined, doing: 'yellow', done: 'green', skipped: 'gray',
}

export function paneTree(el: Elements, s: Subject | undefined, h: PaneHandlers): unknown {
  const { Box, Text, Button, Input } = el
  if (!s) {
    return Text({
      dimColor: true,
      children: ['Aucun sujet rattaché. Colle le lien du ticket Linear, ou présente le sujet à Claude.'],
    })
  }
  const { done, total } = progress(s)
  const title = s.kind === 'ticket' ? `${s.key} · ${s.title}` : s.title

  const header = Box({
    flexDirection: 'row',
    justifyContent: 'space-between',
    children: [
      Text({ bold: true, wrap: 'truncate-end', children: [title] }),
      Text({ dimColor: true, children: [`${done}/${total}`] }),
    ],
  })

  const rows = s.items.map((i) =>
    Box({
      key: `row-${i.id}`,
      flexDirection: 'row',
      columnGap: 1,
      children: [
        Text({ color: GLYPH_COLOR[i.status], dimColor: i.status === 'skipped', children: [GLYPH[i.status]] }),
        Button({
          key: `item-${i.id}`,
          label: i.text,
          plain: true,
          dimColor: i.status === 'skipped',
          onPress: () => h.onCycle(i.id),
        }),
      ],
    }),
  )

  const add = Input({
    key: 'add',
    label: 'Ajouter',
    placeholder: 'nouvelle étape, Entrée',
    value: '',
    submitLabel: 'add',
    onSubmit: (value: string) => {
      const text = value.trim()
      if (text) h.onAdd(text)
    },
  })

  return Box({ flexDirection: 'column', children: [header, ...rows, add] })
}
```

- [ ] **Step 4: Run the test to verify that it passes**

Run: `node --test claude-mods/subject-todo/tests/pane.spec.ts`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/subject-todo/hooks/pane.ts claude-mods/subject-todo/tests/pane.spec.ts
git commit -m "feat(claude-mods): subject-todo pane tree

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: `subject-todo` glue: `register.ts`

**Files:**
- Modify: `claude-mods/subject-todo/hooks/register.ts`, replacing the stub

**Interfaces:**
- Consumes: Tasks 6-9 plus the mods API.
- Produces:
  - `register(on: On): void`
  - the tool `mcp__subject-todo__subject_todo`
  - the command `/todo`

As in Task 5, `tsc` is the gate and the vendored types win.

- [ ] **Step 1: Write `register.ts`**

```ts
// subject-todo: binds the session to a subject (Linear link in a prompt,
// Claude's `bind`, or a dev-<n> branch), gives Claude a tool to keep the list,
// shows it in a pane, and tells Claude about it beside every prompt.

import type { EngineInterface as Api, On } from 'claude-code'
import { ticketFromBranch, ticketToBind } from './binding.ts'
import { TICKET_TEMPLATE } from './template.ts'
import { applyAction, createSubject, cycleItem, renderList, contextFor, type Subject, type ToolAction } from './subject.ts'
import { bindSession, boundKey, loadSubject, mutateSubject, prune, saveSubject } from './store.ts'
import { paneTree, type Elements } from './pane.ts'

const PANE = 'subject-todo'
const TOOL = 'subject_todo'
const TOOL_FULL = 'mcp__subject-todo__subject_todo'

const TOOL_DESCRIPTION = [
  "Tient la todo-list du sujet de la conversation (un ticket ou un sujet libre), affichée à l'utilisateur dans un panneau.",
  "Actions : bind {title} nomme le sujet (le crée s'il n'y en a pas) ; replace {items:[{text,status?}]} remplace la liste ;",
  'update {id, status?, text?} change un item ; add {text, after?} ajoute un item.',
  'Statuts : todo, doing, done, skipped. Mets à jour au fil du travail : doing quand tu commences une étape, done quand elle est faite.',
].join(' ')

const INPUT_SCHEMA = {
  type: 'object',
  properties: {
    action: { type: 'string', enum: ['bind', 'replace', 'update', 'add'] },
    title: { type: 'string' },
    id: { type: 'string' },
    text: { type: 'string' },
    after: { type: 'string' },
    status: { type: 'string', enum: ['todo', 'doing', 'done', 'skipped'] },
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: { text: { type: 'string' }, status: { type: 'string', enum: ['todo', 'doing', 'done', 'skipped'] } },
        required: ['text'],
      },
    },
  },
  required: ['action'],
}

let sessionId = ''
let current: Subject | undefined
let announced = false // the full list goes to Claude once per bind or resume
let lastPromptAt: string | undefined

export function register(on: On): void {
  const nowIso = async ($: Api) => new Date(await $.clock.now()).toISOString()
  const redraw = ($: Api) => $.ui.invalidate('ui.render')

  async function show($: Api, s: Subject): Promise<void> {
    // Older types say open() resolves void, newer docs { isPlaced }: accept both.
    const placed = (await $.ui.open({ id: PANE, title: 'Todo' })) as { isPlaced?: boolean } | undefined
    if (placed && placed.isPlaced === false) $.ui.toast(`${s.kind === 'ticket' ? s.key : s.title} rattaché · /todo`)
  }

  async function bind($: Api, key: string, make: () => Subject): Promise<void> {
    const existing = await loadSubject($.store, key)
    current = existing ?? make()
    if (!existing) await saveSubject($.store, current)
    await bindSession($.store, sessionId, key)
    announced = false
    redraw($)
    await show($, current)
  }

  async function currentBranch($: Api): Promise<string | undefined> {
    try {
      const r = await $.process.run(['git', 'branch', '--show-current'])
      return r.exitCode === 0 ? r.stdout.trim() || undefined : undefined
    } catch {
      return undefined
    }
  }

  // Restore this session's subject, else fall back to a dev-<n> branch.
  async function restore($: Api): Promise<void> {
    sessionId = await $.session.id()
    const key = await boundKey($.store, sessionId)
    current = key ? await loadSubject($.store, key) : undefined
    announced = false
    lastPromptAt = undefined
    if (!current) {
      const ticket = ticketFromBranch(await currentBranch($))
      if (ticket) {
        const now = await nowIso($)
        await bind($, ticket, () => createSubject(ticket, 'ticket', ticket, TICKET_TEMPLATE, now))
      }
    }
    redraw($)
  }

  async function mutate($: Api, fn: (s: Subject, now: string) => ReturnType<typeof cycleItem>) {
    if (!current) return undefined
    const now = await nowIso($)
    const out = await mutateSubject($.store, current.key, (s) => fn(s, now))
    if ('subject' in out) {
      current = out.subject
      redraw($)
    }
    return out
  }

  on('session.start', async ($, e, next) => {
    await $.tool.register({ name: TOOL, description: TOOL_DESCRIPTION, inputSchema: INPUT_SCHEMA })
    await $.command.register({ name: 'todo', description: 'Ouvrir la todo du sujet', immediate: true })
    await prune($.store, await $.clock.now())
    await restore($)
    return next(e)
  })

  // /clear, /resume and /branch reset the session without a session.start.
  on('classic.SessionStart', { source: ['clear', 'resume', 'fork'] }, async ($, e, next) => {
    await restore($)
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    const ticket = ticketToBind(current?.key, e.text)
    if (ticket) {
      const now = await nowIso($)
      await bind($, ticket, () => createSubject(ticket, 'ticket', ticket, TICKET_TEMPLATE, now))
    }
    if (!current) return next(e)
    // Pick up changes from the pane or from another session on the same subject.
    current = (await loadSubject($.store, current.key)) ?? current
    const context = contextFor(current, { since: lastPromptAt, full: !announced })
    announced = true
    lastPromptAt = await nowIso($)
    return next({ ...e, context: [...(e.context ?? []), context] })
  })

  on('tool.call', { tool: TOOL_FULL }, async ($, e) => {
    const a = e as unknown as ToolAction
    if (!current) {
      if (a.action !== 'bind') {
        return { result: 'Aucun sujet rattaché : appelle subject_todo avec action "bind" et un title.' }
      }
      const key = `conv:${sessionId}`
      const now = await nowIso($)
      await bind($, key, () => createSubject(key, 'conversation', a.title, [], now))
      announced = true
      return { result: renderList(current!) }
    }
    const out = await mutate($, (s, now) => applyAction(s, a, 'claude', now))
    if (!out) return { result: 'Aucun sujet rattaché.' }
    if ('error' in out) return { result: `${out.error}\n\n${renderList(current)}` }
    return { result: renderList(out.subject) }
  })

  on('command.run', { command: 'todo' }, async ($) => {
    await $.ui.open({ id: PANE, title: 'Todo', focus: true, closeOnEscape: true })
    return {}
  })

  on('ui.render', { component: 'Pane' }, async ($, e, next) => {
    if (e.requestId !== PANE) return next(e)
    const el = $.ui.resolve(e) as unknown as Elements
    return paneTree(el, current, {
      onCycle: (id) => void mutate($, (s, now) => cycleItem(s, id, now)),
      onAdd: (text) => void mutate($, (s, now) => applyAction(s, { action: 'add', text }, 'user', now)),
    })
  })
}
```

- [ ] **Step 2: Type-check**

Run: `bash claude-mods/check.sh`
Expected: the specs pass and `tsc` prints nothing. Likely type fixes:
- the return type of `ui.render` (the tree from `paneTree` is `unknown`, so
  cast it to the hook's element type);
- the `tool.call` hook returning a string `result`;
- the `classic.SessionStart` matcher.

Note each fix in the commit body.

- [ ] **Step 3: Commit**

```bash
git add claude-mods/subject-todo/hooks/register.ts
git commit -m "feat(claude-mods): wire subject-todo binding, tool, command and pane

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: Docs and the pre-push gate

**Files:**
- Create: `claude-mods/CONTEXT.md`
- Modify: `CONTEXT_MAP.md`, the "Not stow packages" paragraph near line 55
- Modify: `lefthook.yml`, adding a job to the `pre-push` jobs list

Do **not** edit `CLAUDE.md`: it has unrelated uncommitted edits by the user.

- [ ] **Step 1: Write `claude-mods/CONTEXT.md`**

````markdown
# claude-mods

Claude Code [mods](https://code.claude.com/docs/en/plugins/mods/overview) kept
as a local plugin marketplace, `dotfiles-mods`. **Not a stow package**:
`.stow-local-ignore` is `^.*$`, and Claude Code loads these from the repo path.

| Mod | What it does |
|---|---|
| `usage-band` | Replaces `statusLine`: two rows above the prompt. Context is coloured at 40/80; 5h/7d by pace (usage vs elapsed share of the window), floors 10/5 |
| `subject-todo` | `/todo` pane: a list per subject (Linear ticket or conversation) that Claude keeps with the `subject_todo` tool |

Spec: `docs/superpowers/specs/2026-10-07-claude-mods-design.md`.

## Requirements

Claude Code ≥ 2.1.287 (mods GA). Check with `claude --version`.

## Layout

Each mod: `hooks/register.ts` is thin glue over pure modules (`pace`, `layout`,
`git`, `binding`, `subject`, `store`, `pane`). Hooks modules run with **no
Node and no DOM**, so files under `hooks/` must never import `node:*`.

## Checks

```bash
bash claude-mods/check.sh   # node --test on */tests/*.spec.ts + tsc against types/
```

`types/claude-code.d.ts` is vendored. After a Claude Code upgrade, regenerate
it with `/plugin-types` and re-run the checks.

## Dev loop

```bash
claude --plugin-dir claude-mods/usage-band --plugin-dir claude-mods/subject-todo
```

This loads both mods for **that one session only**, and reloads them on save.
Other sessions are untouched.

## Rollback

`usage-band`: disable it in `/plugin`, then restore in
`claude/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

`statusline-command.sh` is kept for this.
````

- [ ] **Step 2: Update `CONTEXT_MAP.md`**

Read the paragraph around line 55, which starts with `Not stow packages:`, and
add `claude-mods/` to it, in the same style as the existing entries. For
example: `` `claude-mods/` (Claude Code mods, loaded from the repo; see its
CONTEXT.md) ``.

- [ ] **Step 3: Add the pre-push job to `lefthook.yml`**

Append to the `pre-push` → `jobs:` list, after the `brewfile` job:

```yaml
    # Pure-logic specs and a type-check of the mods. Runs only when the push
    # touches claude-mods/, and needs no Claude Code, so it works on any version.
    - name: claude-mods
      glob: "claude-mods/**"
      run: bash claude-mods/check.sh
```

- [ ] **Step 4: Verify**

Run: `bash claude-mods/check.sh && lefthook run pre-push --force`
Expected: all specs pass, and `claude-mods` appears in lefthook's summary as
passed. The other jobs report as they do today.

Run: `bash scripts/checks.sh stow`
Expected: `✅ all modules stowed`.

- [ ] **Step 5: Commit**

```bash
git add claude-mods/CONTEXT.md CONTEXT_MAP.md lefthook.yml
git commit -m "docs(claude-mods): context, map entry and pre-push gate

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

## Phase 2: gated on Claude Code ≥ 2.1.287 (stable cask)

**Gate.** Check with `brew info --cask claude-code | head -1`. Only continue
once it shows ≥ 2.1.287 **and** the user has run `brew upgrade --cask
claude-code` themselves. Running sessions keep their loaded binary, so the
upgrade does not interrupt them.

### Task 12: Live verification, in one new session only

**Files:**
- Modify: whatever the checks below show to be wrong. Most likely the two
  `register.ts` files and `types/claude-code.d.ts`.

- [ ] **Step 1: Regenerate the types and re-check**

In a **new** terminal, start `claude` (no plugins), run `/plugin-types`, then
copy the file it writes over `claude-mods/types/claude-code.d.ts`.

Run: `bash claude-mods/check.sh`
Expected: PASS. Fix the type drift in `register.ts` if needed.

- [ ] **Step 2: Validate both plugins**

Run: `claude plugin validate --strict claude-mods/usage-band && claude plugin validate --strict claude-mods/subject-todo`
Expected: no errors. The `hooks:` and `calls:` lines list what you expect, and
nothing more.

- [ ] **Step 3: Load both mods in one session**

Run, in a new terminal:
`claude --plugin-dir claude-mods/usage-band --plugin-dir claude-mods/subject-todo`

The settings `statusLine` is still active, so both bars show. That is useful
for comparing them side by side.

Check each item, and fix before moving on:
1. `/plugin` shows `2 mods active · usage-band, subject-todo`.
2. The `./pace.ts`-style imports with a `.ts` extension resolve. If they do
   not, drop the extensions and set `allowImportingTsExtensions: false`.
3. The band has two rows that match the script's. Colours follow the theme.
   Effort shows, from `turn.step`.
4. The `↻` countdowns show. Pace colours move after a minute without any request.
5. Pasting `https://linear.app/sillant/issue/DEV-1807/x` as the first prompt
   binds the session to that ticket. The pane opens at ≥ 144 columns, or a
   toast appears below that.
6. Claude calls `subject_todo`. Check the tool name in the transcript: it
   should be `mcp__subject-todo__subject_todo`. Also check that the arguments
   arrive at the top level of `e` (`e.action`). Fix `TOOL_FULL` or the cast if
   not.
7. Enter on a pane item cycles its status, and the next prompt's context
   reports it.
8. `/resume` back into the session restores the subject.
9. **`$.store` across processes** (final review, declined to judge). Two
   sessions write *different* keys quickly, then each reads both back. If one
   session's write erases the other's, the store caches the whole file per
   process, and the one-key-per-subject design does not hold. Stop and redesign.
10. Whether core validates `subject_todo` input against `inputSchema`, e.g.
    the `status` enum. `parseAction` guards it either way.
11. Whether the `Ajouter` field empties after a submit while `value: ''` is
    redrawn, and keeps typed text across unrelated redraws.
12. Whether `$.session.id()` already returns the **new** id inside
    `classic.SessionStart` for `clear` and `fork`. If it returns the old one,
    `restore` rebinds the old session.
13. `/branch` keeps the subject, and `/clear` drops it.
14. A commit and push from a GUI git client: `node` and `tsc` (from mise)
    must be on the hook's `PATH`.

- [ ] **Step 4: Settle the marketplace source and the permission rule name**

Read https://code.claude.com/docs/en/plugins/install#add-a-marketplace and
note:
- **(a)** whether a directory source accepts `~` or a relative path;
- **(b)** the exact `permissions.allow` rule for a mod tool. Try
  `mcp__subject-todo__subject_todo` in that one session's `--settings` first.

If (a) needs an absolute path, plan for `scripts/install.sh` to run
`claude plugin marketplace add "$HOME/dotfiles/claude-mods"`, rather than
committing `/Users/oinp` to this public repo.

- [ ] **Step 5: Commit the fixes**

```bash
git add claude-mods/
git commit -m "fix(claude-mods): align with Claude Code <version> after live check

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

Replace `<version>` with the output of `claude --version`, and list each fix
in the body.

### Task 13: Switch over

**Files:**
- Modify: `claude/.claude/settings.json`
- Modify (only if Task 12 Step 4 required it): `scripts/install.sh`

Settings are shared by every session. **Ask the user before this task** and
let them choose the moment: an open session may pick up the `statusLine`
removal live.

- [ ] **Step 1: Register the marketplace**

Use the form settled in Task 12 Step 4. Either add an
`extraKnownMarketplaces.dotfiles-mods` entry, or the `install.sh` line plus a
one-off run of it.

- [ ] **Step 2: Enable the mods, allow the tool and drop `statusLine`**

In `claude/.claude/settings.json`:
- add `"usage-band@dotfiles-mods": true` and `"subject-todo@dotfiles-mods": true`
  to `enabledPlugins`;
- add the rule from Task 12 Step 4(b) to `permissions.allow`, creating
  `permissions` if it is absent;
- delete the `statusLine` block. Keep `statusline-command.sh`.

Run: `jq . claude/.claude/settings.json >/dev/null && echo ok`
Expected: `ok`.

- [ ] **Step 3: Verify in a fresh session**

Start a plain `claude`. `/plugin` lists both mods as active, the band
replaces the status line, and ticking via Claude prompts for no permission.

- [ ] **Step 4: Commit**

```bash
git add claude/.claude/settings.json   # plus scripts/install.sh if changed
git commit -m "feat(claude): switch to the usage-band and subject-todo mods

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```
