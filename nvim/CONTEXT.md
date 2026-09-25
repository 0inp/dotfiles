# Neovim Module Context

## Purpose
Configuration for [Neovim](https://neovim.io/), a modern Vim-based text editor.

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `init.lua`               | Entry point for Neovim configuration | `~/.config/nvim/init.lua`          |
| `nvim-pack-lock.json`    | Lockfile for plugin versions         | `~/.config/nvim/nvim-pack-lock.json` |
| `lua/`                   | Lua modules for plugins and settings | `~/.config/nvim/lua/`               |
| `after/`                 | Post-load configurations             | `~/.config/nvim/after/`             |

## Dependencies
- **Neovim**: Install via Homebrew (`brew install neovim`).
- **Plugins**: Managed by Neovim's native `vim.pack.add` (0.12), called from
  each file under `lua/plugins/`. There is no `lazy.nvim` and no `plugins.lua`.

## Key Features
- **Lua Config**: Modern Lua-based configuration.
- **Plugins**: Native `vim.pack`, pinned by `nvim-pack-lock.json`.
- **Keybindings**: Custom shortcuts for editing and navigation.
- **LSP**: Language Server Protocol integration. Servers are declared in
  `lua/plugins/lsp.lua`; most are installed by Mason via mason-tool-installer.

## Markdown: three readers, and the one that fails silently

`lua/plugins/markdown.lua` wires three separate ways to read the same file, and
they are not interchangeable:

| Key | Where | Plugin / tool |
|---|---|---|
| `<leader>or` | in the buffer | `render-markdown.nvim` — default; nothing to start, nothing to crash |
| `<leader>ob` / `<leader>oB` | in the browser | `markdown-preview.nvim` — Mermaid, KaTeX, scroll sync |
| `<leader>ot` | in the terminal | `leaf -w` in a vsplit — a read-only pane beside a Claude pane |

`markdown-plus.nvim` is the *editing* layer (headings, lists, tables, callouts).
It has no rendering module, so `render-markdown.nvim` is a complement, not a
duplicate.

**Those keys are under `<leader>o`, not `<leader>m`, and must stay there.**
`maplocalleader` is Space, the same as `mapleader`, so markdown-plus's
`<localleader>m*` bindings all land on `<leader>m*` — 28 letters of it. Binding
into that range from `after/ftplugin/markdown.lua` silently shadows them: this
ftplugin runs after the plugin's own, and markdown-plus only declines to
overwrite keys that already existed when *it* loaded. A first pass here took
`<leader>ml`, `mp` and `mr`, quietly killing "insert link", "smart paste URL as
link" and "renumber ordered lists". A separate prefix also survives the plugin
claiming more letters in a later release.

**`instance_mode` must stay `"multi"`.** In the plugin's `"takeover"` mode one
Neovim owns the fixed port 8421 and one shared browser tab. A *second* Neovim
takes the secondary branch of `markdown_preview/init.lua`: it writes its
content, adopts the primary's token, and **returns before reaching either
`open_browser` call site**. So with two files open in two instances — the normal
case here — `:MarkdownPreview` in the second one does nothing at all: no tab, no
error, no message. Confirmed by `lsof -nP -iTCP:8421`, which showed one nvim
holding the port while the other was mute. Same class of trap as the inert
lefthook hooks: the failure path returns cleanly instead of complaining.

**Spell is `fr,en`, deliberately both.** A fiche is genuinely bilingual —
French prose carrying English technical vocabulary — so a word is accepted when
either dictionary knows it. The Neovim default, `spelllang=en`, underlined
roughly every French word. Four things make this usable:

- `fr.utf-8.spl` does **not** ship with Neovim. `scripts/install.sh` fetches it
  into `~/.local/share/nvim/site/spell`. Without it the setting silently
  degrades to English and Neovim warns `Cannot find word list "fr.utf-8.spl"`.
- **`spell/fr.utf-8.add` is a versioned project dictionary.** `zg` writes there,
  so vocabulary accumulates across machines. It is seeded from the words
  actually flagged across every fiche, keeping only those that appeared **twice
  or more** — one-off oddities stay flagged, which is the only thing still
  catching a real typo. Measured over the nine fiches, by counting `]s` presses:
  **255 → 173** flagged occurrences.
- **Neovim only compiles `.add` into `.add.spl` when you press `zg` or `zw`.** A
  dictionary arriving by `git pull` would therefore never take effect, silently.
  `lua/plugins/markdown.lua` compares mtimes at startup and runs `mkspell!` when
  the source is newer. The `.add.spl` is gitignored (`nvim/.gitignore`), and
  `nvim/.stow-local-ignore` excludes that `.gitignore` so stow does not try to
  claim `~/.gitignore`, which the `git` module already owns.
- `spelloptions=camel` splits `staleTime` into "stale" + "Time" (344 → 321 on
  the same corpus, with a cruder metric — small, but free).

Code needs no exclusion rule: the markdown treesitter query marks only
`(inline)` as `@spell`, and `markdown_inline` marks code spans, link URLs and
entity references `@nospell`. Measured on a mixed file — a fenced `js` block, a
`` `codeSpan` `` and a URL slug raise nothing. **This only holds while the
treesitter highlighter is attached.** A probe that set `spelllang` without
starting treesitter reported every code token as a spelling error, which is a
measurement artefact, not a config bug.

**The biggest remaining source of noise is ticket references**, and it cannot be
fixed here: the spell checker treats `DEV-1937` as one word, so the set is
unbounded and a dictionary cannot cover it. There are 73 of them across the
fiches and only 2 are in backticks. Writing them as `` `DEV-1937` `` would take
the residue from ~173 to ~102 for free, because code spans are already
`@nospell`. That is a convention for whatever *writes* the fiches, not a Neovim
setting.

Grammar (agreement, conjugation) is *not* covered — `spell` only checks words in
isolation. That would need `ltex_plus` (LanguageTool) in `lsp.lua`; Mason's
`ltex-ls-plus` ships a bundled JRE, so it needs no system Java (this machine has
none: `/usr/bin/java` is the macOS stub).

## TypeScript: `tsc`, not `ts_ls`
TS/JS uses **`tsc`** — TypeScript 7's native (Go) language server, run as
`tsc --lsp --stdio`. It replaced `ts_ls` (the old Node `tsserver`); upstream
lspconfig also deprecated the interim `tsgo` beta in favour of `tsc`.

Its binary does **not** come from Mason (there is no `typescript` package in the
registry) — it comes from mise, via `"npm:typescript" = "7"`. Servers in that
situation must be listed in `non_mason_servers` in `lsp.lua`, which does two
things: keeps the name out of `ensure_installed`, and enables the server by hand
with `vim.lsp.enable`. That second part matters — **mason-lspconfig's
`automatic_enable` only fires for servers Mason itself installed**, so a
non-Mason server that is merely configured will never attach.

Corollary: removing a server from `lsp_servers` does not disable it if Mason
still has the package installed. `ts_ls` kept attaching until
`:MasonUninstall typescript-language-server` was run.

## AI Notes
- Focus on `init.lua` and `lua/` for core configuration.
- Use `nvim-pack-lock.json` to track plugin versions.
- Test changes by launching `nvim`.
