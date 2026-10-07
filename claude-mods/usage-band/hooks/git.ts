// Parses the two git calls the band makes. The mod runs them through
// $.process.run; parsing stays here so it is testable without a session.

export type GitInfo = { branch?: string; worktree?: string; staged: number; modified: number }

// One `status --porcelain=v2 --branch` yields branch *and* dirty counts.
export const STATUS_ARGV = ['git', '--no-optional-locks', 'status', '--porcelain=v2', '--branch'] as const
export const REVPARSE_ARGV = [
  'git', 'rev-parse', '--path-format=absolute', '--show-toplevel', '--git-dir', '--git-common-dir',
] as const

export function parseStatus(stdout: string): Omit<GitInfo, 'worktree'> {
  let oid = ''
  let head: string | undefined
  let staged = 0
  let modified = 0
  for (const line of stdout.split('\n')) {
    if (line.startsWith('# branch.oid ')) oid = line.slice(13).slice(0, 7)
    else if (line.startsWith('# branch.head ')) head = line.slice(14)
    else if (line.startsWith('1 ') || line.startsWith('2 ')) {
      const xy = line.slice(2, 4)
      if (xy[0] !== '.') staged++
      if (xy[1] !== '.') modified++
    }
  }
  return { branch: head === '(detached)' ? oid : head, staged, modified }
}

// In a linked worktree, --git-dir points into the main repo's .git/worktrees/.
export function parseWorktree(stdout: string): string | undefined {
  const [top, gitDir, commonDir] = stdout.trim().split('\n')
  if (!top || !gitDir || !commonDir || gitDir === commonDir) return undefined
  return top.split('/').pop()
}
