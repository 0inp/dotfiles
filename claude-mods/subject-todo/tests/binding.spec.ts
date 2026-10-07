import { test } from 'node:test'
import assert from 'node:assert/strict'
import { inheritOnFork, ticketFromBranch, ticketFromText, ticketToBind } from '../hooks/binding.ts'
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

// Review finding 5: /branch gets a new session id with no binding.
test('inheritOnFork: a fork keeps the subject of the session it came from', () => {
  assert.equal(inheritOnFork('fork', undefined, 'DEV-1807'), 'DEV-1807')
  assert.equal(inheritOnFork('fork', 'conv:x', 'DEV-1807'), undefined) // already bound: keep that
  assert.equal(inheritOnFork('clear', undefined, 'DEV-1807'), undefined) // /clear starts fresh
  assert.equal(inheritOnFork('resume', undefined, 'DEV-1807'), undefined)
  assert.equal(inheritOnFork('fork', undefined, undefined), undefined)
})
