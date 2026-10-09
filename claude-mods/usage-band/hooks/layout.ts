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
