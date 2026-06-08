# MCP (Multi-Tool Coordination Protocol)

## Router

### Priority Rules
1. **Precision First**: `read`, `grep`, `glob`, `bash` run before `edit`/`write`.
2. **Rate Limits**:
   - `skill`: 2 calls per minute.
   - `task`: 3 calls per minute.

### User Confirmation
- Required for: `edit`, `write`, `skill`.

## Tool Coordination

### Parallel Execution
- **Safe Tools**: `read`, `grep`, `glob`, `webfetch` run in parallel.
- **Risky Tools**: `edit`, `write`, `bash` run sequentially.

### State Tracking
- Log all tool calls in `.pi/agent/sessions/`.
- Preserve last 5 states for rollback.

## Error Handling
- **Block on Failure**: Halt if `read`/`grep` fails.
- **Retry Limits**: Max 2 retries for `webfetch`/`task`.