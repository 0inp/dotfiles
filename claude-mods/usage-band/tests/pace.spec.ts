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
