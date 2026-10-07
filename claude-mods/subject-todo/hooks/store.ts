// Subjects and session bindings in $.store, which every session on the machine
// shares. get-then-set is not atomic, so every change re-reads the subject
// right before writing it, and each subject has its own key.

import type { Outcome, Subject } from './subject.ts'

export interface KV {
  get(key: string): Promise<unknown>
  set(key: string, value: unknown): Promise<void>
  delete(key: string): Promise<void>
  keys(): Promise<string[]>
}

const SUBJECT = 'subject:'
const SESSION = 'session:'
const DAY_MS = 86_400_000

function isSubject(v: unknown): v is Subject {
  if (typeof v !== 'object' || v === null) return false
  const s = v as Record<string, unknown>
  return typeof s.key === 'string' && typeof s.title === 'string' && typeof s.updatedAt === 'string' && Array.isArray(s.items)
}

export async function loadSubject(kv: KV, key: string): Promise<Subject | undefined> {
  const v = await kv.get(SUBJECT + key)
  return isSubject(v) ? v : undefined
}

export async function saveSubject(kv: KV, s: Subject): Promise<void> {
  await kv.set(SUBJECT + s.key, s)
}

export async function mutateSubject(kv: KV, key: string, fn: (s: Subject) => Outcome): Promise<Outcome> {
  const fresh = await loadSubject(kv, key)
  if (!fresh) return { error: `Le sujet ${key} est introuvable.` }
  const out = fn(fresh)
  if ('subject' in out) await saveSubject(kv, out.subject)
  return out
}

export async function bindSession(kv: KV, sessionId: string, key: string): Promise<void> {
  await kv.set(SESSION + sessionId, key)
}

export async function boundKey(kv: KV, sessionId: string): Promise<string | undefined> {
  const v = await kv.get(SESSION + sessionId)
  return typeof v === 'string' ? v : undefined
}

// Conversation subjects untouched for maxAgeMs go, then every binding whose
// subject no longer exists. Ticket subjects are kept. Returns how many keys went.
export async function prune(kv: KV, now: number, maxAgeMs = 30 * DAY_MS): Promise<number> {
  let removed = 0
  const keys = await kv.keys()
  const live = new Set<string>()
  for (const k of keys.filter((k) => k.startsWith(SUBJECT))) {
    const s = await kv.get(k)
    const stale = isSubject(s) && s.kind === 'conversation' && now - Date.parse(s.updatedAt) > maxAgeMs
    if (stale) {
      await kv.delete(k)
      removed++
    } else live.add(k.slice(SUBJECT.length))
  }
  for (const k of keys.filter((k) => k.startsWith(SESSION))) {
    const target = await kv.get(k)
    if (typeof target !== 'string' || !live.has(target)) {
      await kv.delete(k)
      removed++
    }
  }
  return removed
}
