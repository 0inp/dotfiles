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
// git must never hold up a prompt: a stuck lock or a huge repo gives up fast.
const GIT_TIMEOUT = { timeoutMs: 2_000 }

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
      const [st, rp] = await Promise.all([$.process.run(STATUS_ARGV, GIT_TIMEOUT), $.process.run(REVPARSE_ARGV, GIT_TIMEOUT)])
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
    void refreshGit($, true)
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
    void refreshGit($, true)
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
