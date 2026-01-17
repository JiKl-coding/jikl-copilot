---
name: git-sync-rebase
description: Safely sync a branch with origin/main using fetch + rebase, with an optional "accept current" conflict policy.
---

# git-sync-rebase

## Instructions

Use this skill when you need to:

- commit local changes (if requested),
- fetch from origin,
- rebase onto `origin/main`,
- resolve conflicts using a deterministic policy.

### Workflow

#### Inspect

- Run `git status --porcelain=v1 -b`
- If needed: `git diff --stat`

#### Fetch

- Run `git fetch --prune origin`

#### (Optional) Add + commit

- Stage: `git add -A` (or the user-specified scope)
- Commit: require a user-provided message (ask if missing)

#### Rebase

- Run `git rebase origin/main`

#### If conflicts happen

- List conflicted files: `git diff --name-only --diff-filter=U`

If the user requested “accept current”:

- For each conflicted file:

  - `git checkout --ours -- <file>`
  - `git add <file>`

- Continue: `git rebase --continue`
- If Git reports an empty commit: `git rebase --skip`

#### Verify

- `git status -sb` should be clean

### Safety

- Do not force-push unless explicitly requested.
- If a force push is required after rebase, prefer `git push --force-with-lease` and ask for confirmation.
