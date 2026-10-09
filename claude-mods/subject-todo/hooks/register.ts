// subject-todo: binds the session to a subject (Linear link in a prompt,
// Claude's `bind`, or a dev-<n> branch), gives Claude a tool to keep the list,
// shows it in a pane, and tells Claude about it beside every prompt.

import type { EngineInterface as Api, On, RenderElement } from 'claude-code'
import { inheritOnFork, ticketFromBranch, ticketToBind } from './binding.ts'
import { TICKET_TEMPLATE } from './template.ts'
import { applyAction, contextFor, createSubject, cycleItem, parseAction, renderList, type Subject } from './subject.ts'
import { bindSession, boundKey, loadSubject, mutateSubject, prune, saveSubject, serialQueue, type KV } from './store.ts'
import { paneTree, type Elements } from './pane.ts'

const PANE = 'subject-todo'
const TOOL = 'subject_todo'
const TOOL_FULL = 'mcp__subject-todo__subject_todo'

const TOOL_DESCRIPTION = [
  "Tient la todo-list du sujet de la conversation (un ticket ou un sujet libre), affichée à l'utilisateur dans un panneau.",
  "Actions : bind {title} nomme le sujet (le crée s'il n'y en a pas) ; replace {items:[{text,status?}]} remplace la liste ;",
  'update {id, status?, text?} change un item ; add {text, after?} ajoute un item.',
  'Statuts : todo, doing, done, skipped. Mets à jour au fil du travail : doing quand tu commences une étape, done quand elle est faite.',
].join(' ')

const INPUT_SCHEMA = {
  type: 'object',
  properties: {
    action: { type: 'string', enum: ['bind', 'replace', 'update', 'add'] },
    title: { type: 'string' },
    id: { type: 'string' },
    text: { type: 'string' },
    after: { type: 'string' },
    status: { type: 'string', enum: ['todo', 'doing', 'done', 'skipped'] },
    items: {
      type: 'array',
      items: {
        type: 'object',
        properties: { text: { type: 'string' }, status: { type: 'string', enum: ['todo', 'doing', 'done', 'skipped'] } },
        required: ['text'],
      },
    },
  },
  required: ['action'],
}

let sessionId = ''
let current: Subject | undefined
let announced = false // the full list goes to Claude once per bind or resume
let lastPromptAt: string | undefined
// One queue for every store write from this process (pane, tool, binding).
const serial = serialQueue()

// The validator follows $ only into functions declared at the top of this
// file, never across an import, and refuses $.store passed as a value. So
// store.ts gets this adapter, whose calls keep the $.store.<method> spelling.
function kv($: Api): KV {
  return {
    get: (key) => $.store.get(key),
    set: (key, value) => $.store.set(key, value),
    delete: (key) => $.store.delete(key),
    keys: () => $.store.keys(),
  }
}

const nowIso = async ($: Api) => new Date(await $.clock.now()).toISOString()
const redraw = ($: Api) => $.ui.invalidate('ui.render')

// An unasked pane waits undrawn below 144 columns; ui.open resolves void,
// so ask ui.panes whether it was placed and say so when it was not.
async function show($: Api, s: Subject): Promise<void> {
  await $.ui.open({ id: PANE, title: 'Todo' })
  const pane = (await $.ui.panes()).find((p) => p.id === PANE)
  if (pane && !pane.isPlaced) $.ui.toast(`${s.kind === 'ticket' ? s.key : s.title} rattaché · /todo`)
}

async function bind($: Api, key: string, make: () => Subject): Promise<void> {
  current = await serial(async () => {
    const existing = await loadSubject(kv($), key)
    const s = existing ?? make()
    if (!existing) await saveSubject(kv($), s)
    await bindSession(kv($), sessionId, key)
    return s
  })
  announced = false
  redraw($)
  await show($, current)
}

async function currentBranch($: Api): Promise<string | undefined> {
  try {
    const r = await $.process.run(['git', 'branch', '--show-current'], { timeoutMs: 2_000 })
    return r.exitCode === 0 ? r.stdout.trim() || undefined : undefined
  } catch {
    return undefined
  }
}

// Restore this session's subject: its own binding, else (on /branch) the
// parent's subject, else a dev-<n> branch.
async function restore($: Api, source = 'startup'): Promise<void> {
  const previous = current?.key
  sessionId = await $.session.id()
  const bound = await boundKey(kv($), sessionId)
  const inherited = inheritOnFork(source, bound, previous)
  if (inherited) await serial(() => bindSession(kv($), sessionId, inherited))
  const key = bound ?? inherited
  current = key ? await loadSubject(kv($), key) : undefined
  announced = false
  lastPromptAt = undefined
  if (!current) {
    const ticket = ticketFromBranch(await currentBranch($))
    if (ticket) {
      const now = await nowIso($)
      await bind($, ticket, () => createSubject(ticket, 'ticket', ticket, TICKET_TEMPLATE, now))
    }
  }
  redraw($)
}

async function mutate($: Api, fn: (s: Subject, now: string) => ReturnType<typeof cycleItem>) {
  if (!current) return undefined
  const key = current.key
  const now = await nowIso($)
  const out = await serial(() => mutateSubject(kv($), key, (s) => fn(s, now)))
  if ('subject' in out) {
    current = out.subject
    redraw($)
  }
  return out
}

export function register(on: On): void {
  on('session.start', async ($, e, next) => {
    await $.tool.register({ name: TOOL, description: TOOL_DESCRIPTION, inputSchema: INPUT_SCHEMA })
    await $.command.register({ name: 'todo', description: 'Ouvrir la todo du sujet', immediate: true })
    await prune(kv($), await $.clock.now())
    await restore($)
    return next(e)
  })

  // /clear, /resume and /branch reset the session without a session.start.
  on('classic.SessionStart', { source: ['clear', 'resume', 'fork'] }, async ($, e, next) => {
    await restore($, e.source)
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    const ticket = ticketToBind(current?.key, e.text)
    if (ticket) {
      const now = await nowIso($)
      await bind($, ticket, () => createSubject(ticket, 'ticket', ticket, TICKET_TEMPLATE, now))
    }
    if (!current) return next(e)
    // Pick up changes from the pane or from another session on the same subject.
    current = (await loadSubject(kv($), current.key)) ?? current
    const context = contextFor(current, { since: lastPromptAt, full: !announced })
    announced = true
    lastPromptAt = await nowIso($)
    return next({ ...e, context: [...(e.context ?? []), context] })
  })

  on('tool.call', { tool: TOOL_FULL }, async ($, e) => {
    const a = parseAction(e)
    if ('error' in a) return { result: current ? `${a.error}\n\n${renderList(current)}` : a.error }
    if (!current) {
      if (a.action !== 'bind') {
        return { result: 'Aucun sujet rattaché : appelle subject_todo avec action "bind" et un title.' }
      }
      const key = `conv:${sessionId}`
      const now = await nowIso($)
      await bind($, key, () => createSubject(key, 'conversation', a.title, [], now))
      announced = true
      return { result: renderList(current!) }
    }
    const out = await mutate($, (s, now) => applyAction(s, a, 'claude', now))
    if (!out) return { result: 'Aucun sujet rattaché.' }
    if ('error' in out) return { result: `${out.error}\n\n${renderList(current)}` }
    return { result: renderList(out.subject) }
  })

  on('command.run', { command: 'todo' }, async ($) => {
    await $.ui.open({ id: PANE, title: 'Todo', focus: true, closeOnEscape: true })
    return {}
  })

  on('ui.render', { component: 'Pane' }, async ($, e, next) => {
    if (e.requestId !== PANE) return next(e)
    const el = $.ui.resolve(e) as unknown as Elements
    // paneTree is typed loosely so its specs can draw with fakes; here it is
    // drawn with the real elements, so the tree it returns is a RenderElement.
    return paneTree(el, current, {
      onCycle: (id) => void mutate($, (s, now) => cycleItem(s, id, now)),
      onAdd: (text) => void mutate($, (s, now) => applyAction(s, { action: 'add', text }, 'user', now)),
    }) as RenderElement
  })
}
