# Domain Docs

This repo uses a **multi-context layout**:
- A `CONTEXT-MAP.md` file at the repo root points to per-context `CONTEXT.md` files.
- ADRs are stored in `docs/adr/` or per-context ADR directories.

## Consumer Rules
- Skills like `improve-codebase-architecture`, `diagnose`, and `tdd` read:
  - `CONTEXT-MAP.md` to locate the relevant `CONTEXT.md`.
  - `docs/adr/` or per-context ADR directories for architectural decisions.