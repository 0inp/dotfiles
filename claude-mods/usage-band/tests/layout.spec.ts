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
