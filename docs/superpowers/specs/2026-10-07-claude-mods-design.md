# Claude Code mods: usage band + subject todo

Date: 2026-10-07
Status: design approved, awaiting Claude Code ≥ 2.1.287 (stable cask is 2.1.285)

## Goal

Two Claude Code [mods](https://code.claude.com/docs/en/plugins/mods/overview),
kept in this repo:

1. **`usage-band`**: replaces `claude/.claude/statusline-command.sh` as a trial.
   Same information, drawn in the band above the prompt, with consumption
   coloured by *pace* rather than by fixed thresholds.
2. **`subject-todo`**: a side pane holding a todo list for the subject of the
   conversation, usually a Linear ticket. Claude keeps it up to date as the
   work goes. The user ticks things off from the pane now and then.

Success: one glance at the band says how much room is left, and one glance at
the pane says where the subject stands, without re-reading the conversation.

## Constraints and findings

- Mods need Claude Code v2.1.287+. Homebrew's stable `claude-code` cask is
  2.1.285 and `claude-code@latest` is 2.1.292. Decision: wait for stable rather
  than switch casks.
- There is no `StatusLine` render site. `$.ui.status(text)` is one plain,
  uncoloured line beside Claude Code's own notices, with no width information.
  So the only way to keep two coloured rows is the `AbovePrompt` band, which
  means the usage moves **above** the prompt and is shared with other mods.
- `$.session.usage()` / `session.measure` give `context`, `rateLimits[]`
  (`kind`, `percentUsed`, `resetsAt`) and `cost`. Git data (branch, worktree,
  dirty counts) still needs a `git` process, exactly as the script does today.
- Mods are not sandboxed. These are our own, so no trust issue.

## 1. `usage-band`

### Rendering

Two rows in the `AbovePrompt` band, same layout as the script:

```
~/dotfiles  ⌂ tooling-refresh  ⑂ chore/tooling-refresh +2 ~1
Opus 5.5 (1M) · high  ▓▓▓▓░░░░░░ 37%  5h 24% ↻1h12  7d 41% ↻3j
```

- `↻` is the time left until the window resets, computed from `resetsAt`.
- No cost segment.
- Width: `e.props.bodyColumns` replaces `COLUMNS`. `shortenPath` and the
  row-1 rules (path is elastic, worktree chip dropped before the branch, branch
  never shortened) are ported unchanged.
- Row-2 shedding order, first dropped first: `↻` countdowns → 7d → 5h → effort
  → bar.
- The hook returns `Box([ourRows, await next(e)])` so other mods' band content
  (for example `you-should-know`) stays visible.

### Levels and colours

Three semantic levels mapped to ANSI-16 theme slots, so the band follows the
terminal palette (Gruvbox). No hex colours.

| Level | Colour |
|---|---|
| `OK` | `green` |
| `WARNING` | `yellow` |
| `DANGER` | `red` |
| no data | `gray` |

**Context fill**, fixed thresholds: `< 40%` OK, `≥ 40%` WARNING, `≥ 80%` DANGER.

**5h and 7d windows**, by pace:

```
elapsed = windowMs − (resetsAt − now)       // windowMs: 5h or 7d
budget  = elapsed / windowMs × 100          // 4h into 5h → 80
used    = percentUsed

used < floor             → OK        // floor: 10 for 5h, 5 for 7d
used ≥ budget            → DANGER
used ≥ 0.8 × budget      → WARNING
otherwise                → OK
no resetsAt              → no data (gray)
```

Reference cases (these become tests):

| Moment | Budget | Used | Level |
|---|---|---|---|
| 4h into 5h | 80 | 60 | OK |
| 4h into 5h | 80 | 70 | WARNING |
| 4h into 5h | 80 | 85 | DANGER |
| day 2 of 7 | 28.6 | 41 | DANGER |
| 10 min into 5h | 3.3 | 4 | OK (under the 10 floor) |

### Data sources

| Data | Source | Refresh |
|---|---|---|
| context, 5h/7d, `resetsAt` | `session.measure` | pushed; redraw only when `changed` includes `context` or `rateLimits` |
| model | `$.session.model()` | on `session.measure` |
| effort | `turn.step` → `e.effort` (to verify) | each model request; segment omitted if unavailable |
| branch, worktree, `+staged ~modified` | `$.process.run('git', ['status','--porcelain=v2','--branch'])` | `session.start`, `turn.complete`, after a `tool.call` to Bash/Edit/Write; 5 s cache |
| pace and `↻` | computed | `$.clock.every(60_000)`, since the budget grows with time alone |

### Files

- `hooks/pace.ts`: pure `paceLevel()` and `contextLevel()`. No mods API.
- `hooks/layout.ts`: pure `shortenPath`, `composeRow1`, `composeRow2`, `fit`.
  Input is data plus column count; output is segments with levels.
- `hooks/register.ts`: wires events and state, and calls the two modules above
  from `ui.render { component: 'AbovePrompt' }`.

## 2. `subject-todo`

### Model

```ts
type Subject = {
  key: string            // 'DEV-1807' | 'conv:<sessionId>'
  kind: 'ticket' | 'conversation'
  title: string
  items: Item[]
  updatedAt: string      // ISO
}
type Item = {
  id: string             // short and stable, e.g. 'a3f'
  text: string
  status: 'todo' | 'doing' | 'done' | 'skipped'
  by: 'claude' | 'user'  // who made the last change
}
```

`skipped` marks a template step that does not apply to this ticket, so its
history is kept instead of the step being deleted.

### Storage

| Key | Where | Why |
|---|---|---|
| `subject:<key>` | `$.store` | one key per subject, shared by every session and worktree on the machine |
| `session:<sessionId>` → subject key | `$.store` | the binding survives `/resume`, which resets `$.state` |
| current subject | `$.state` | the pane reads it and redraws when it changes |

- Every write re-reads the key immediately before `set`, because `$.store`
  get/set is not atomic across sessions.
- On `session.start`, conversation subjects untouched for 30 days are pruned,
  along with their `session:*` bindings. Ticket subjects are kept. The store
  limit is 4 MiB.
- `$.state` is reloaded from `$.store` on `session.start` and on
  `classic.SessionStart` with `source` in `clear | resume | fork`.

### Binding a session to a subject

In priority order, applied only while the session is unbound:

1. **`prompt.submit`**: a Linear URL `linear.app/<org>/issue/<TEAM>-<n>` in the
   prompt binds the session to that ticket key. The user starts every Sillant
   conversation with the ticket link, so this is the main path.
2. **Tool `subject_todo` action `bind`**: for a free-form intro, such as a
   dotfiles topic, Claude creates a `conversation` subject with a title.
3. **Branch fallback** at `session.start`: a branch matching `dev-\d+`
   (case-insensitive) gives `DEV-<n>`.

If a ticket subject has no list yet, it is created from the ticket template.
The template is hard-coded in the mod (`hooks/template.ts`):

1. Lire le ticket et comprendre le sujet
2. Écrire la fiche de cadrage
3. Relire la fiche de cadrage et la corriger si nécessaire
4. 1ère implémentation
5. Préparer la QA de dev manuelle
6. Faire la QA de dev
7. Corriger les retours de QA
8. Ouvrir les PRs en ready-to-review
9. Adresser les commentaires de PRs
10. Merge
11. Nettoyer : worktrees, fiche doc, branches git, etc.

Conversation subjects have no template. Claude builds the list from the intro.

### Keeping Claude informed

While the session is bound, `prompt.submit` adds a short `context` to every
prompt:

> Sujet DEV-1807 (3/11). En cours : 1ère implémentation. L'utilisateur a validé
> depuis le panneau : Relire la fiche de cadrage. Tiens la liste à jour avec
> l'outil `subject_todo`.

The "validated from the pane" part lists items with `by: 'user'` changed since
the previous prompt, so Claude does not redo them. On the first prompt of a
ticket, the context also asks Claude to adapt the template with `replace`.

### Tool `subject_todo`

Registered with `$.tool.register`.

| Action | Params | Typical use |
|---|---|---|
| `bind` | `title` | free-form intro → conversation subject |
| `replace` | `items: {text, status}[]` | adapt the template at the start of a ticket |
| `update` | `id`, `status?`, `text?` | tick a step as work progresses |
| `add` | `text`, `after?` (item id) | a step found along the way |

Every call returns the updated list as text. There is no `remove`: use
`skipped`, or `replace`. Calls marked `by: 'claude'`.

### Pane

- `/todo` toggles the pane. It is registered with `immediate: true`, so it
  works while Claude is busy.
- On bind, the mod also opens the pane on its own. Claude Code only places an
  unasked pane at ≥ 144 columns (110 once opened by hand). When it is not
  placed, a toast says `DEV-1807 rattaché · /todo`.
- Header: `<key> · <title>` and `done/total`, where skipped items count in
  neither.
- One plain `Button` per item, `key: 'item-<id>'`. Enter cycles
  `○ todo → ▶ doing → ✓ done → – skipped → ○ todo`, sets `by: 'user'`, and saves.
- Glyph colours use theme slots: `▶` yellow, `✓` green, `–` dim.
- An `Input` at the bottom (`label: 'Ajouter'`) appends a `todo` item.
- Unbound session: the pane says so, and offers no list.

### Files

- `hooks/binding.ts`: pure Linear-URL and branch parsing.
- `hooks/template.ts`: the ticket template.
- `hooks/store.ts`: subject and binding read/write over `$.store`, with
  re-read-before-write and pruning.
- `hooks/pane.ts`: the `ui.render { component: 'Pane' }` tree.
- `hooks/register.ts`: events, tool, command.
- `types/index.d.ts`: `PluginState` for the current subject key.

## 3. Repo integration

### Layout

```
claude-mods/                          not a stow package
├── .stow-local-ignore                ^.*$
├── CONTEXT.md
├── .claude-plugin/marketplace.json   lists usage-band and subject-todo
├── usage-band/
└── subject-todo/
```

- `.stow-local-ignore` with `^.*$` follows the `docs/` precedent. `stow -t ~ */`
  skips the directory and `check_stow` stays green.
- `CONTEXT_MAP.md` lists it under "Not stow packages".
- `claude-mods/CONTEXT.md` covers loading, the dev loop
  (`claude --plugin-dir claude-mods/<mod>`), tests and rollback.

### `claude/.claude/settings.json`

- `extraKnownMarketplaces.dotfiles-mods`: a directory source pointing at
  `claude-mods/`.
- `enabledPlugins`: `usage-band@dotfiles-mods`, `subject-todo@dotfiles-mods`.
- `permissions.allow`: the `subject_todo` tool, so ticking a step never prompts.
- `statusLine`: removed for the trial. `statusline-command.sh` stays in the repo.

### Checks

Lefthook pre-push, only when `claude-mods/**` changed:
`claude plugin validate --strict` and `claude plugin test` for each plugin.
These gate repo drift only. Outdated packages are not their concern.

### Tests (`claude plugin test`)

- `usage-band`: `pace.ts` against the reference cases table, floors and
  missing `resetsAt`; `layout.ts` shedding at several widths, and `shortenPath`.
- `subject-todo`: URL and branch parsing; template creation; the status cycle;
  binding restored after `/resume`; pane rendering, with buttons pressed and
  the input typed into by `key`.

### Rollback

Disable `usage-band` in `/plugin`, then restore the three-line `statusLine`
block in `settings.json`. `subject-todo` is independent and keeps working.

## Verify first on ≥ 2.1.287

These come before any code that depends on them:

1. **Marketplace `source` format** for a local directory, and whether it
   accepts `~` or a relative path. If it needs an absolute path, do not commit
   `/Users/oinp` to this public repo: have `scripts/install.sh` register the
   marketplace (`claude plugin marketplace add <path>`) instead.
2. **`e.effort` on `turn.step`.** If it is absent, drop the effort segment.
3. **The permission rule name** for a tool a mod registers.
4. Whether the status-line JSON already carries `resets_at`. Background
   information only; it does not block anything.

## Out of scope

- Session cost in the band.
- A Linear sync of the list, in either direction.
- Inferring progress automatically from `gh pr create`, merges or worktree removal.
- Per-repo templates. There is one ticket template, hard-coded.
