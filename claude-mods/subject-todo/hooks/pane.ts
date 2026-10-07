// The pane's element tree. Takes the element factories from $.ui.resolve(e)
// as an argument, so the specs can draw it with fakes and press its buttons.

import { GLYPH, progress, type Status, type Subject } from './subject.ts'

type Factory = (props: Record<string, unknown>) => unknown
export type Elements = { Box: Factory; Text: Factory; Button: Factory; Input: Factory }
export type PaneHandlers = { onCycle(id: string): void; onAdd(text: string): void }

// Theme slots only. Button takes no colour, so the glyph is a Text beside it.
const GLYPH_COLOR: Record<Status, string | undefined> = {
  todo: undefined, doing: 'yellow', done: 'green', skipped: 'gray',
}

export function paneTree(el: Elements, s: Subject | undefined, h: PaneHandlers): unknown {
  const { Box, Text, Button, Input } = el
  if (!s) {
    return Text({
      dimColor: true,
      children: ['Aucun sujet rattaché. Colle le lien du ticket Linear, ou présente le sujet à Claude.'],
    })
  }
  const { done, total } = progress(s)
  const title = s.kind === 'ticket' ? `${s.key} · ${s.title}` : s.title

  const header = Box({
    flexDirection: 'row',
    justifyContent: 'space-between',
    children: [
      Text({ bold: true, wrap: 'truncate-end', children: [title] }),
      Text({ dimColor: true, children: [`${done}/${total}`] }),
    ],
  })

  const rows = s.items.map((i) =>
    Box({
      key: `row-${i.id}`,
      flexDirection: 'row',
      columnGap: 1,
      children: [
        Text({ color: GLYPH_COLOR[i.status], dimColor: i.status === 'skipped', children: [GLYPH[i.status]] }),
        Button({
          key: `item-${i.id}`,
          label: i.text,
          plain: true,
          dimColor: i.status === 'skipped',
          onPress: () => h.onCycle(i.id),
        }),
      ],
    }),
  )

  const add = Input({
    key: 'add',
    label: 'Ajouter',
    placeholder: 'nouvelle étape, Entrée',
    value: '',
    submitLabel: 'add',
    onSubmit: (value: string) => {
      const text = value.trim()
      if (text) h.onAdd(text)
    },
  })

  return Box({ flexDirection: 'column', children: [header, ...rows, add] })
}
