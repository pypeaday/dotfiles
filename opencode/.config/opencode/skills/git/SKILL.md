---
name: git
description: "Git operations including commits, branches, worktrees, and safety protocols. Use on 'git', 'commit', 'branch', 'worktree', 'rebase', 'merge'."
---

# Git Skill

Safe, consistent git operations for agents.

## Safety Protocol (CRITICAL)

These rules are NON-NEGOTIABLE:

- **Never amend pushed commits** - verify with `git status` showing "Your branch is ahead"
- **Never force push to main/master** - warn user if requested
- **Never skip hooks** - no `--no-verify` or `--no-gpg-sign`
- **Never commit secrets** - reject `.env`, `credentials.json`, `*.key`, `*.pem`
- **Never push automatically** - leave pushing to the user. This includes `git push` AND `gh pr create`. Creating PRs is equivalent to pushing.
- **Always verify branch state** before destructive operations

## Conventional Commits

Format: `<type>(<scope>): <description>`

| Type | When to Use |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change, no feature/fix |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `chore` | Build, tooling, deps |
| `ci` | CI/CD changes |
| `revert` | Reverting previous commit |

Rules:
- Imperative mood, present tense ("add" not "added")
- First line under 72 characters
- Scope is optional but helpful: `feat(auth): add login endpoint`
- Focus on "why" not "what"

## Workflow: Making a Commit

```bash
# 1. Check state
git status

# 2. Review changes
git diff                 # unstaged
git diff --cached        # staged

# 3. Stage files (prefer explicit over `git add .`)
git add <specific-files>

# 4. Commit with conventional message
git commit -m "type(scope): description"

# 5. Verify
git log -1
git status

# 6. DO NOT PUSH - leave for user
```

## Workflow: Branching

```bash
# Check current branch
git branch --show-current

# Create feature branch
git checkout -b feat/short-description

# Create from specific base
git checkout -b fix/bug-description main
```

Branch naming conventions:
- `feat/` - new features
- `fix/` - bug fixes
- `chore/` - maintenance
- `refactor/` - code restructuring
- `docs/` - documentation

## Rebase vs Merge

**Context-dependent** - choose based on situation:

| Use Rebase | Use Merge |
|------------|-----------|
| Cleaning local commits before PR | Preserving branch history |
| Linear history preferred | Shared branch with others |
| Feature branch behind main | Main into feature (public branch) |

**NEVER rebase pushed commits** unless user explicitly requests it (requires force push).

## Danger Zone Checklist

Before ANY destructive operation (`reset --hard`, `push --force`, `rebase -i`, `commit --amend`):

- [ ] Is this a local-only change? (not pushed)
- [ ] Did I verify branch state with `git status`?
- [ ] Did the user explicitly request this?
- [ ] Is the work recoverable if something goes wrong?

If ANY checkbox is unclear, **ask the user first**.

## Worktree Patterns

Convention: worktrees go in `./tree/` directory.

```bash
# List worktrees
git worktree list

# Add worktree for existing branch
git worktree add ./tree/feat-branch feat-branch

# Add worktree with new branch
git worktree add -b fix/new-fix ./tree/fix-new-fix main

# Remove worktree
git worktree remove ./tree/old-branch

# Clean up stale entries
git worktree prune
```

## Amend Rules

Only use `git commit --amend` when ALL conditions are met:

1. User explicitly requested amend, OR commit succeeded but pre-commit hook auto-modified files
2. HEAD commit was created by you in this session (verify: `git log -1 --format='%an %ae'`)
3. Commit has NOT been pushed to remote (verify: `git status` shows "Your branch is ahead")

**If commit FAILED or was REJECTED by hook** - NEVER amend. Fix the issue and create a NEW commit.

## Quick Reference

```bash
# Status and history
git status
git log --oneline -10
git diff HEAD~1

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Discard unstaged changes (DANGEROUS)
git checkout -- <file>

# Stash work temporarily
git stash
git stash pop

# Check remote state
git fetch --dry-run
git log origin/main..HEAD
```
