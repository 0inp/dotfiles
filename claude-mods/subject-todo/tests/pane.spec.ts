import { test } from 'node:test'
import assert from 'node:assert/strict'
import { paneTree, type Elements } from '../hooks/pane.ts'
import { applyAction, createSubject, type Subject } from '../hooks/subject.ts'

type Node = { type: string; props: Record<string, any> }
const el: Elements = {
  Box: (props) => ({ type: 'Box', props }),
  Text: (props) => ({ type: 'Text', props }),
  Button: (props) => ({ type: 'Button', props }),
  Input: (props) => ({ type: 'Input', props }),
}
function walk(n: unknown, out: Node[] = []): Node[] {
  if (n && typeof n === 'object' && 'type' in n) {
    out.push(n as Node)
    for (const c of ((n as Node).props.children ?? []) as unknown[]) walk(c, out)
  }
  return out
}
const textOf = (nodes: Node[]) => nodes.filter((n) => n.type === 'Text').flatMap((n) => n.props.children).filter((c) => typeof c === 'string').join('|')
const NOW = '2026-10-07T12:00:00.000Z'

function subject(): Subject {
  let s = createSubject('DEV-1807', 'ticket', 'Export CSV', ['Lire', 'Cadrer', 'QA'], NOW)
  const done = applyAction(s, { action: 'update', id: s.items[0].id, status: 'done' }, 'claude', NOW)
  if ('subject' in done) s = done.subject
  const skip = applyAction(s, { action: 'update', id: s.items[2].id, status: 'skipped' }, 'claude', NOW)
  if ('subject' in skip) s = skip.subject
  return s
}

test('unbound: says how to bind, no controls', () => {
  const nodes = walk(paneTree(el, undefined, { onCycle() {}, onAdd() {} }))
  assert.ok(textOf(nodes).includes('Aucun sujet'))
  assert.ok(!nodes.some((n) => n.type === 'Button' || n.type === 'Input'))
})

test('header shows key, title and done/total', () => {
  const t = textOf(walk(paneTree(el, subject(), { onCycle() {}, onAdd() {} })))
  assert.ok(t.includes('DEV-1807 · Export CSV'))
  assert.ok(t.includes('1/2'))
})

test('one keyed button per item; pressing cycles that item', () => {
  const s = subject()
  const pressed: string[] = []
  const nodes = walk(paneTree(el, s, { onCycle: (id) => pressed.push(id), onAdd() {} }))
  const buttons = nodes.filter((n) => n.type === 'Button')
  assert.deepEqual(buttons.map((b) => b.props.key), s.items.map((i) => `item-${i.id}`))
  buttons[1].props.onPress({ surface: 'terminal' })
  assert.deepEqual(pressed, [s.items[1].id])
})

test('glyph colours and dimmed skipped items', () => {
  const nodes = walk(paneTree(el, subject(), { onCycle() {}, onAdd() {} }))
  const glyph = (g: string) => nodes.find((n) => n.type === 'Text' && n.props.children?.[0] === g)
  assert.equal(glyph('✓')?.props.color, 'green')
  assert.equal(nodes.find((n) => n.type === 'Button' && n.props.label === 'QA')?.props.dimColor, true)
})

test('the input adds trimmed text and ignores blanks', () => {
  const added: string[] = []
  const nodes = walk(paneTree(el, subject(), { onCycle() {}, onAdd: (t) => added.push(t) }))
  const input = nodes.find((n) => n.type === 'Input')!
  assert.equal(input.props.key, 'add')
  input.props.onSubmit('   ')
  input.props.onSubmit('  PR vicat ')
  assert.deepEqual(added, ['PR vicat'])
})
