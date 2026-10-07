// Which ticket a session is about. A Linear link in a prompt wins; a dev-<n>
// branch is the fallback. Keys are upper-cased so DEV-1807 is one subject
// whatever the spelling.

const LINEAR_URL = /linear\.app\/[\w-]+\/issue\/([a-z]+-\d+)/i
const DEV_BRANCH = /(?:^|[/_-])(dev-\d+)(?=$|[/_-])/i

export function ticketFromText(text: string): string | undefined {
  return LINEAR_URL.exec(text)?.[1]?.toUpperCase()
}

export function ticketFromBranch(branch: string | undefined): string | undefined {
  return branch ? DEV_BRANCH.exec(branch)?.[1]?.toUpperCase() : undefined
}

// Only an unbound session binds from a prompt: a second link pasted later is
// a reference, not a change of subject.
export function ticketToBind(boundKey: string | undefined, text: string): string | undefined {
  return boundKey === undefined ? ticketFromText(text) : undefined
}

// /branch forks the conversation under a new session id with no binding of its
// own; the fork is about the same subject, so it inherits the parent's key.
// /clear and /resume do not: one starts fresh, the other has its own binding.
export function inheritOnFork(source: string, bound: string | undefined, previous: string | undefined): string | undefined {
  return source === 'fork' && bound === undefined ? previous : undefined
}
