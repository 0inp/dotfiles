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

test('day 5 of 7: budget 71.4, warning from 57.1', () => {
  const r = resetIn(2 * D)
  assert.equal(paceLevel(50, r, NOW), 'ok')
  assert.equal(paceLevel(58, r, NOW), 'warning')
  assert.equal(paceLevel(72, r, NOW), 'danger')
})

test('day 2: budget 28.6, 41 is danger', () => {
  assert.equal(paceLevel(41, resetIn(5 * D), NOW), 'danger')
  assert.equal(paceLevel(20, resetIn(5 * D), NOW), 'ok')
})

test('the floor silences the start of the window', () => {
  const r = resetIn(7 * D - H) // 1h into the window, budget 0.6
  assert.equal(paceLevel(4, r, NOW), 'ok')
  assert.equal(paceLevel(6, r, NOW), 'danger')
})

test('no or unreadable resetsAt gives no data', () => {
  assert.equal(paceLevel(50, undefined, NOW), 'none')
  assert.equal(paceLevel(50, 'not a date', NOW), 'none')
})

test('a reset already in the past counts as a full window', () => {
  assert.equal(paceLevel(85, resetIn(-MIN), NOW), 'warning')
})
