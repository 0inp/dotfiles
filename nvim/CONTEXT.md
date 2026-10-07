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

`lua/plugins/markdown.lua` wires three ways to read the same file:

| Key | Where | Plugin / tool |
|---|---|---|
| `<leader>or` | in the buffer | `render-markdown.nvim` — default; nothing to start |
| `<leader>ob` / `<leader>oB` | in the browser | `markdown-preview.nvim` — Mermaid, KaTeX, scroll sync |
| `<leader>ot` | in the terminal | `leaf -w` in a vsplit, beside a Claude pane |

`markdown-plus.nvim` is the *editing* layer (headings, lists, tables, callouts).
It has no rendering module, so `render-markdown.nvim` complements it.

**Those keys live under `<leader>o`, not `<leader>m`, and must stay there.**
`maplocalleader` is Space, the same as `mapleader`, so markdown-plus's
`<localleader>m*` bindings occupy 28 letters of `<leader>m*`. Binding there from
`after/ftplugin/markdown.lua` shadows them silently: this ftplugin loads after the
plugin's own, and markdown-plus only declines to overwrite keys that existed when
*it* loaded. A separate prefix also survives the plugin claiming more letters.

**`instance_mode` must stay `"multi"`.** Under `"takeover"` one Neovim owns the
fixed port 8421 and one shared browser tab. A second Neovim takes the secondary
branch of `markdown_preview/init.lua` — it writes its content, adopts the primary's
token, and returns before reaching either `open_browser` call site. With two files
open in two instances, `:MarkdownPreview` in the second does nothing at all: no tab,
no error, no message.

**Spell is `fr,en`, both on purpose.** A fiche is bilingual — French prose carrying
English technical vocabulary — so a word passes when either dictionary knows it.
Four things make that usable:

- `fr.utf-8.spl` is not shipped with Neovim. `scripts/install.sh` fetches it into
  `~/.local/share/nvim/site/spell`. Without it the setting degrades to English and
  Neovim warns `Cannot find word list "fr.utf-8.spl"`.
- `spell/fr.utf-8.add` is a versioned project dictionary, so `zg` accumulates
  vocabulary across machines. It holds only terms that recur across the fiches;
  one-off oddities stay flagged, which is what still catches a real typo.
- **Neovim compiles `.add` into `.add.spl` only on `zg` or `zw`**, so a dictionary
  arriving by `git pull` would stay inert. `lua/plugins/markdown.lua` compares
  mtimes at startup and runs `mkspell!` when the source is newer. The `.add.spl` is
  gitignored, and `nvim/.stow-local-ignore` excludes that `.gitignore` so stow does
  not claim `~/.gitignore`, which the `git` module owns.
- `spelloptions=camel` splits `staleTime` into "stale" + "Time".

Code needs no exclusion rule: the markdown query marks only `(inline)` as `@spell`,
and `markdown_inline` marks code spans, link URLs and entity references `@nospell`.
**That only holds while the treesitter highlighter is attached** — measure spell
noise without it and every code token reads as an error.

**Ticket references are the floor on the remaining noise.** The spell checker treats
`DEV-1937` as one word, so the set is unbounded and no dictionary covers it. Writing
them as `` `DEV-1937` `` removes them for free, since code spans are `@nospell` —
a convention for whatever *writes* the fiches, not a Neovim setting.

Grammar (agreement, conjugation) is *not* covered — `spell` only checks words in
isolation. That would need `ltex_plus` (LanguageTool) in `lsp.lua`; Mason's
`ltex-ls-plus` ships a bundled JRE, so it needs no system Java.

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

## Key discovery: mini.clue, and the LSP keys it does not own

`lua/plugins/clue.lua` is the which-key layer — `mini.clue`, already inside the
mini.nvim of `base.lua`, so nothing new is downloaded. `<leader>pk`
(`MiniExtra.pickers.keymaps()`) stays the fuzzy-search route for the same
information.

**Most of the goto keys are Neovim's, not this config's.** `grr`, `gri`, `grt`,
`grn`, `gra`, `grx`, `gO` and insert-mode `<C-S>` are mapped unconditionally by
`runtime/lua/vim/_core/defaults.lua`, with no LSP client required — the runtime
comment says that is deliberate, so behaviour does not change depending on what
is attached. Only `gd` and `K` are set here, in `lsp.lua`. `lsp.lua` then
shadows `grr`/`gri` with `MiniExtra.pickers.lsp`, which reaches the same requests
through the `on_list` hook `vim.lsp.buf.*` already accepts, instead of the
default quickfix list. `grt` and `gO` were left on the stock behaviour.

**A missing clue trigger fails silently in the useful direction.** Triggers are
buffer-local mappings that must be the *most recent* ones on the buffer; when
they are not, the key still works — it just stops working until the clue window
is up. mini.clue re-asserts them on `BufWinEnter` and `LspAttach` itself, so no
extra autocmd is needed; requiring `plugins.clue` last in `plugins/init.lua`
only covers the first buffer.

**Those callbacks are `vim.schedule_wrap`ped, so `nvim -c ':nmap g'` shows no
trigger at all** and the setup reads as broken. Verify from a real session, or a
`pty.fork()` with the check deferred past `VimEnter` — the same trap as the
`zvm_after_init_commands` and `fnox activate` hooks documented in `CLAUDE.md`.

**`s`, and operator-pending `a`/`i`, are deliberately not triggers.** `s` is
mini.surround's prefix, and a trigger there puts the query delay on every
`saiw`; mini.clue documents that Operator-pending triggers (mini.ai's `a`/`i`)
have no foolproof support with custom operators. Insert-mode `<C-x>` *is* safe
next to mini.completion, which replays `<C-x><C-o>` through
`nvim_feedkeys(..., 'n', ...)` — no remap, so the trigger never sees it.

## AI Notes
- Focus on `init.lua` and `lua/` for core configuration.
- Use `nvim-pack-lock.json` to track plugin versions.
- Test changes by launching `nvim`.
