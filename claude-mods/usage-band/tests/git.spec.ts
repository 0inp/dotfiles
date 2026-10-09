import { test } from 'node:test'
import assert from 'node:assert/strict'
import { parseStatus, parseWorktree } from '../hooks/git.ts'

test('branch and dirty counts, untracked ignored', () => {
  const out = [
    '# branch.oid 0df6b3e1234567',
    '# branch.head main',
    '1 M. N... 100644 100644 100644 a b CLAUDE.md',
    '1 .M N... 100644 100644 100644 a b nvim/init.lua',
    '1 MM N... 100644 100644 100644 a b both.lua',
    '2 R. N... 100644 100644 100644 a b R100 new\told',
    '? untracked.txt',
  ].join('\n')
  assert.deepEqual(parseStatus(out), { branch: 'main', staged: 3, modified: 2 })
})

test('detached head shows the short oid', () => {
  assert.equal(parseStatus('# branch.oid 0df6b3e1234567\n# branch.head (detached)\n').branch, '0df6b3e')
})

test('not a repo: empty output gives no branch and zero counts', () => {
  assert.deepEqual(parseStatus(''), { branch: undefined, staged: 0, modified: 0 })
})

test('worktree: name only when git-dir differs from the common dir', () => {
  assert.equal(
    parseWorktree('/Users/me/dotfiles.tooling\n/Users/me/dotfiles/.git/worktrees/tooling\n/Users/me/dotfiles/.git\n'),
    'dotfiles.tooling',
  )
  assert.equal(parseWorktree('/Users/me/dotfiles\n/Users/me/dotfiles/.git\n/Users/me/dotfiles/.git\n'), undefined)
  assert.equal(parseWorktree(''), undefined)
})
