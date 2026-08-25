# Mise Module Context

## Purpose
Configuration for [Mise](https://mise.jdx.dev/), a polyglot runtime version manager (successor to `asdf`).

## Key Files
| File                     | Description                          | Symlink Target                     |
|--------------------------|--------------------------------------|------------------------------------|
| `config.toml`            | Mise plugins, versions, and settings | `~/.config/mise/config.toml`       |

## Dependencies
- **Mise**: Install via Homebrew (`brew install mise`).

## Key Features
- **Runtime Management**: Node, Python and Go versions are pinned here.
- **Backends**: beyond runtimes, mise installs CLI tools from other ecosystems.
  `"npm:typescript" = "7"` is used to keep a global TypeScript 7 on PATH.
- **Settings**: Global and project-specific configurations.

## Why TypeScript lives here
Neovim's `tsc` language server (nvim-lspconfig) runs `tsc --lsp --stdio`, which
only exists in TypeScript 7+. lspconfig prefers a project's own
`node_modules/.bin/tsc` but **skips it when that binary predates 7.0**, falling
back to `$PATH`. Without a global TS 7, the LSP silently fails to attach in any
repo still pinned to TypeScript 5 or 6. Mason has no `typescript` package, which
is why this is a mise entry rather than a Mason one.

## AI Notes
- Focus on `config.toml` for plugins and versions.
- Test changes with `mise current`; check tool binaries with `mise which <tool>`.
- Mise is activated **interactive-only** (`.zshrc`). A non-interactive shell
  will not see these tools — relevant when testing anything that shells out.