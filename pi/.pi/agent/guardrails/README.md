# Guardrails

## Permission Rules

### File Operations
- **Read**: Allowed for all files in workspace.
- **Edit/Write**: Require user confirmation. Block if:
  - File contains secrets (e.g., `API_KEY`, `SECRET`, `PASSWORD`).
  - File is in `.git/` or `.pi/agent/sessions/`.

### Tool Usage
- **Bash**: Block if command contains:
  - `rm -rf`
  - `git push --force`
  - `chmod -R`
  - `mv /`
  - `dd`
- **WebFetch**: Block if URL matches:
  - `localhost` (unless explicitly allowed).
  - Private IP ranges (e.g., `192.168.*.*`).

### Session Safety
- **State Tracking**: Log all tool calls in `.pi/agent/sessions/`.
- **Undo Support**: Preserve last 5 states for rollback.

## Safety Hooks

### Pre-Execution
- **Read Before Edit**: Block `edit`/`write` if `read` not called first.
- **Grep Before Assume**: Block assumptions about code without `grep`.

### Post-Execution
- **Verify After Change**: Run `lint`/`test` after `edit`/`write`.
- **Cite Sources**: Require `file:line` or `URL` for all claims.

### Irreversible Actions
- **User Confirmation**: Required for `edit`/`write`/`skill`.
- **Auto Clarity**: Drop caveman tone for irreversible actions.