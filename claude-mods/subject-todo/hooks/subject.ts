// The subject and its items, and every change Claude or the user can make.
// Pure: every function returns a new Subject (or an error) and takes `now`
// as an argument, so the specs control time.

export type Status = 'todo' | 'doing' | 'done' | 'skipped'
export type Actor = 'claude' | 'user'
export type Item = { id: string; text: string; status: Status; by: Actor; changedAt: string }
export type Subject = {
  key: string
  kind: 'ticket' | 'conversation'
  title: string
  items: Item[]
  updatedAt: string
}
export type ToolAction =
  | { action: 'bind'; title: string }
  | { action: 'replace'; items: { text: string; status?: Status }[] }
  | { action: 'update'; id: string; status?: Status; text?: string }
  | { action: 'add'; text: string; after?: string }
export type Outcome = { subject: Subject } | { error: string }

export const GLYPH: Record<Status, string> = { todo: '○', doing: '▶', done: '✓', skipped: '–' }
export const STATUS_CYCLE: Record<Status, Status> = { todo: 'doing', doing: 'done', done: 'skipped', skipped: 'todo' }

// Three base-36 characters: short enough for Claude to quote, unique per subject.
function newId(taken: ReadonlySet<string>, rand: () => number): string {
  for (;;) {
    const id = Math.floor(rand() * 46656).toString(36).padStart(3, '0')
    if (!taken.has(id)) return id
  }
}

function makeItems(texts: readonly { text: string; status?: Status; id?: string }[], actor: Actor, now: string, rand: () => number, taken = new Set<string>()): Item[] {
  return texts.map((t) => {
    const id = t.id ?? newId(taken, rand)
    taken.add(id)
    return { id, text: t.text, status: t.status ?? 'todo', by: actor, changedAt: now }
  })
}

export function createSubject(
  key: string,
  kind: Subject['kind'],
  title: string,
  texts: readonly string[],
  now: string,
  rand: () => number = Math.random,
): Subject {
  return { key, kind, title, items: makeItems(texts.map((text) => ({ text })), 'claude', now, rand), updatedAt: now }
}

export function progress(s: Subject): { done: number; total: number } {
  const counted = s.items.filter((i) => i.status !== 'skipped')
  return { done: counted.filter((i) => i.status === 'done').length, total: counted.length }
}

const unknownId = (id: string): Outcome => ({ error: `Aucun item avec l'id "${id}".` })

function edit(s: Subject, id: string, patch: Partial<Pick<Item, 'status' | 'text'>>, actor: Actor, now: string): Outcome {
  if (!s.items.some((i) => i.id === id)) return unknownId(id)
  const items = s.items.map((i) => (i.id === id ? { ...i, ...patch, by: actor, changedAt: now } : i))
  return { subject: { ...s, items, updatedAt: now } }
}

export function cycleItem(s: Subject, id: string, now: string): Outcome {
  const item = s.items.find((i) => i.id === id)
  return item ? edit(s, id, { status: STATUS_CYCLE[item.status] }, 'user', now) : unknownId(id)
}

export function applyAction(s: Subject, a: ToolAction, actor: Actor, now: string, rand: () => number = Math.random): Outcome {
  switch (a.action) {
    case 'bind':
      return { subject: { ...s, title: a.title, updatedAt: now } }
    case 'update': {
      const patch: Partial<Pick<Item, 'status' | 'text'>> = {}
      if (a.status) patch.status = a.status
      if (a.text) patch.text = a.text
      return edit(s, a.id, patch, actor, now)
    }
    case 'add': {
      const [item] = makeItems([{ text: a.text }], actor, now, rand, new Set(s.items.map((i) => i.id)))
      if (a.after === undefined) return { subject: { ...s, items: [...s.items, item], updatedAt: now } }
      const at = s.items.findIndex((i) => i.id === a.after)
      if (at < 0) return unknownId(a.after)
      const items = [...s.items.slice(0, at + 1), item, ...s.items.slice(at + 1)]
      return { subject: { ...s, items, updatedAt: now } }
    }
    case 'replace': {
      // Reuse the id of an existing item with the same text, so ids Claude
      // already holds stay valid across an adaptation.
      const byText = new Map(s.items.map((i) => [i.text, i.id]))
      const wanted = a.items.map((t) => ({ ...t, id: byText.get(t.text) }))
      const taken = new Set(wanted.flatMap((t) => (t.id ? [t.id] : [])))
      return { subject: { ...s, items: makeItems(wanted, actor, now, rand, taken), updatedAt: now } }
    }
  }
}

export function renderList(s: Subject): string {
  const { done, total } = progress(s)
  const header = s.kind === 'ticket' ? `${s.key} · ${s.title} (${done}/${total})` : `${s.title} (${done}/${total})`
  return [header, ...s.items.map((i) => `[${i.id}] ${GLYPH[i.status]} ${i.text}`)].join('\n')
}

// What Claude reads beside each prompt. Short by default; `full` adds the list
// with ids (first prompt after a bind or a resume) and, for an untouched
// ticket, asks Claude to adapt the template.
export function contextFor(s: Subject, opts: { since?: string; full: boolean }): string {
  const { done, total } = progress(s)
  const name = s.kind === 'ticket' ? `Sujet ${s.key} : ${s.title}` : `Sujet : ${s.title}`
  const lines = [`${name} (${done}/${total}).`]
  const doing = s.items.filter((i) => i.status === 'doing').map((i) => i.text)
  if (doing.length > 0) lines.push(`En cours : ${doing.join(', ')}.`)
  const since = opts.since
  const byUser = since === undefined ? [] : s.items.filter((i) => i.by === 'user' && i.changedAt > since)
  if (byUser.length > 0) {
    lines.push(`Changé par l'utilisateur depuis le panneau : ${byUser.map((i) => `${i.text} (${i.status})`).join(', ')}.`)
  }
  lines.push("Tiens la liste à jour avec l'outil subject_todo (update, add, replace) au fil du travail.")
  if (opts.full) {
    const untouched = s.kind === 'ticket' && s.items.every((i) => i.status === 'todo' && i.by === 'claude')
    if (untouched) {
      lines.push("C'est le modèle par défaut : adapte-le à ce ticket avec replace (passe en skipped ce qui ne s'applique pas, ajoute ce qui manque).")
    }
    lines.push('', renderList(s))
  }
  return lines.join('\n')
}

const STATUSES: readonly string[] = ['todo', 'doing', 'done', 'skipped']
const isStatus = (v: unknown): v is Status => typeof v === 'string' && STATUSES.includes(v)
const nonEmpty = (v: unknown): v is string => typeof v === 'string' && v.trim() !== ''

// The tool's input is model output: check each action's own fields before it
// reaches the store, so a malformed call is an error Claude can read and retry,
// never a subject saved with an undefined title or text.
export function parseAction(input: unknown): ToolAction | { error: string } {
  const a = (typeof input === 'object' && input !== null ? input : {}) as Record<string, unknown>
  switch (a.action) {
    case 'bind':
      return nonEmpty(a.title) ? { action: 'bind', title: a.title.trim() } : { error: 'bind demande un title non vide.' }
    case 'add':
      if (!nonEmpty(a.text)) return { error: 'add demande un text non vide.' }
      return typeof a.after === 'string' ? { action: 'add', text: a.text.trim(), after: a.after } : { action: 'add', text: a.text.trim() }
    case 'update': {
      if (!nonEmpty(a.id)) return { error: 'update demande un id.' }
      if (a.status === undefined && a.text === undefined) return { error: 'update demande un status ou un text.' }
      if (a.status !== undefined && !isStatus(a.status)) return { error: `status invalide : ${String(a.status)}.` }
      if (a.text !== undefined && !nonEmpty(a.text)) return { error: 'update : text ne peut pas être vide.' }
      const out: ToolAction = { action: 'update', id: a.id }
      if (a.status !== undefined) out.status = a.status
      if (nonEmpty(a.text)) out.text = a.text.trim()
      return out
    }
    case 'replace': {
      if (!Array.isArray(a.items) || a.items.length === 0) return { error: 'replace demande une liste items non vide.' }
      const items: { text: string; status?: Status }[] = []
      for (const it of a.items as unknown[]) {
        const o = (typeof it === 'object' && it !== null ? it : {}) as Record<string, unknown>
        if (!nonEmpty(o.text)) return { error: 'replace : chaque item demande un text non vide.' }
        if (o.status !== undefined && !isStatus(o.status)) return { error: `status invalide : ${String(o.status)}.` }
        items.push(o.status !== undefined ? { text: o.text.trim(), status: o.status } : { text: o.text.trim() })
      }
      return { action: 'replace', items }
    }
    default:
      return { error: `action inconnue : ${String(a.action)}. Actions : bind, replace, update, add.` }
  }
}
