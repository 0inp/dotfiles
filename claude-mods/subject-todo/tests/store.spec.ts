import { test } from 'node:test'
import assert from 'node:assert/strict'
import { bindSession, boundKey, loadSubject, mutateSubject, prune, saveSubject, serialQueue, type KV } from '../hooks/store.ts'
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

// Review finding 2: a structurally broken subject must read as no subject.
test('loadSubject: rejects broken items and a missing kind', async () => {
  const kv = memoryKV()
  const good = ticket()
  kv.map.set('subject:A', { ...good, key: 'A', items: [null] })
  kv.map.set('subject:B', { ...good, key: 'B', items: [{ ...good.items[0], status: 'finished' }] })
  kv.map.set('subject:C', { ...good, key: 'C', kind: undefined })
  kv.map.set('subject:D', { ...good, key: 'D', items: [{ id: 'x' }] })
  for (const k of ['A', 'B', 'C', 'D']) assert.equal(await loadSubject(kv, k), undefined, k)
  kv.map.set('subject:E', { ...good, key: 'E' })
  assert.ok(await loadSubject(kv, 'E'))
})

// Review finding 3: two mutations from one process must not interleave.
test('serialQueue: concurrent mutations on a slow store both land', async () => {
  const kv = memoryKV()
  const slow: KV = {
    get: async (k) => { await new Promise((r) => setTimeout(r, 5)); return kv.get(k) },
    set: async (k, v) => { await new Promise((r) => setTimeout(r, 5)); return kv.set(k, v) },
    delete: kv.delete,
    keys: kv.keys,
  }
  await saveSubject(kv, ticket())
  const serial = serialQueue()
  const add = (text: string) => () =>
    mutateSubject(slow, 'DEV-1807', (s) => applyAction(s, { action: 'add', text }, 'user', NOW))
  await Promise.all([serial(add('A')), serial(add('B'))])
  assert.deepEqual(((await loadSubject(kv, 'DEV-1807')) as Subject).items.map((i) => i.text), ['Lire', 'A', 'B'])
})

test('serialQueue: a failing job does not block the next one', async () => {
  const serial = serialQueue()
  await assert.rejects(serial(async () => { throw new Error('boom') }))
  assert.equal(await serial(async () => 42), 42)
})
