---
description: Safe Nexus discovery + Session Plan (read-only by default)
---

# Nexus Command (Safe)

Safely inspect Nexus state without claiming or mutating anything.

**Usage**: `/nexus` (discover + read-only) | `/nexus start` (mutating) | `/nexus claim <id>` (mutating)

## Principles

- **Safe by default**: No mutations unless explicitly requested
- **Minimal context**: Aggressively filter results to avoid huge outputs
- **Project-aware**: Warn if `NEXUS_PROJECT` unset; never auto-pick in safe mode
- **Mutations are explicit**: Only in `/nexus start` or `/nexus claim <id>` with confirmation
- **Output format**: JSON → summarize to <=20 items with id, title, project, status, priority, claimed_by, parent (for issues); id, for_issue, plan_type, status, ready (for plans)

## Workflow (Read-Only)

1. **Check project scope**: `printenv NEXUS_PROJECT`
   - If unset: warn and suggest `export NEXUS_PROJECT="<project>"` to `.envrc`
   
2. **Gather minimal data** (only run if prev succeeds):
   ```bash
   nexus --help           # Once, to verify CLI works
   nexus status --json    # Current claims
   nexus issue list --status open --top-level --limit 20 --json
   nexus plan list --not-ready --limit 20 --json
   nexus next --json      # Peek at next work (no --claim flag)
   ```

3. **Output: Session Plan** grouped by readiness:
   - **Ready to start**: List issues with subagent suggestion (builder, tester, explore)
   - **Needs refinement**: Missing scope/criteria
   - **Blocked on plan**: Feature plan not approved
   - **Suggested next action**: One concrete human action

4. **Failure handling**: If any command fails, report error + one likely cause + next step. Do not proceed with mutations.

## When User Requests Mutations (/nexus start, /nexus claim <id>)

Require **explicit confirmation before** any claim/create/update.

If `NEXUS_PROJECT` is unset, propose a default (repo-name match) and ask to confirm **Mode B**:

```text
NEXUS_PROJECT is unset. Use "<repo-name>"? [y/n] (Mode B)
```

```text
Ready to claim <issue_id> "<title>"? [y/n]
```

Then:
```bash
export NEXUS_PROJECT="<project>"
nexus issue claim <id>
```

Only proceed if user confirms.
