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
