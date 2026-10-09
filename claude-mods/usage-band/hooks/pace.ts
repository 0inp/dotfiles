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
}
