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
