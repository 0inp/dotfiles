// The two colour rules of the usage band. Pure: no mods API, so the specs run
// under plain node.

export type Level = 'ok' | 'warning' | 'danger' | 'none'

// Only the weekly window is shown: Ultra drops the 5h one.
export const WINDOW_MS = 7 * 86_400_000

// Below this much usage the window is never coloured: early in the window the
// budget is tiny, and one request would otherwise turn it red.
export const FLOOR = 5

export function contextLevel(percent: number | undefined): Level {
  if (percent === undefined) return 'none'
  if (percent >= 80) return 'danger'
  if (percent >= 40) return 'warning'
  return 'ok'
}

// Compares usage with the share of the window that has already elapsed.
export function paceLevel(used: number, resetsAt: string | undefined, now: number): Level {
  if (resetsAt === undefined) return 'none'
  const reset = Date.parse(resetsAt)
  if (Number.isNaN(reset)) return 'none'
  if (used < FLOOR) return 'ok'
  const elapsed = Math.min(WINDOW_MS, Math.max(0, WINDOW_MS - (reset - now)))
  const budget = (elapsed / WINDOW_MS) * 100
  if (used >= budget) return 'danger'
  if (used >= 0.8 * budget) return 'warning'
  return 'ok'
}
