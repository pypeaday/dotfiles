---
name: code-review
description: 'Ruthless code review for Python, Kubernetes, and AWS. Hunts for downstream problems, security issues, and unnecessary complexity. Triggers on "review", "check", "audit", "what could go wrong", "done yet", "ready to merge".'
---

# Code Review Skill

Ruthless review focused on Python, Kubernetes, and AWS. Only flag things that matter — bugs, security holes, logic errors. Never comment on style or formatting.

## Review Process

### 1. Understand the Change
- Read the PR description / commit message first
- Understand the **intent** before reading code
- Check what files changed and their relationship

### 2. Review Order
1. **Data model / schema changes** — these cascade everywhere
2. **API boundaries** — breaking changes, missing validation
3. **Business logic** — correctness, edge cases
4. **Error handling** — what happens when things fail
5. **Tests** — do they test the right things, not just coverage
6. **Configuration** — environment-specific gotchas

### 3. Severity Classification
| Level | Meaning | Action |
|-------|---------|--------|
| **CRITICAL** | Bug, security vulnerability, data loss | Must fix before merge |
| **WARNING** | Will cause problems eventually | Fix now or create ticket |
| **SMELL** | Code quality concern, future maintenance burden | Author's discretion |

### 4. Writing Good Review Comments
- State the **problem**, not just "this is wrong"
- Explain the **consequence** (what breaks, when)
- Suggest a **fix** (concrete, not vague)
- One issue per comment

## Python Red Flags

### Security (CRITICAL)
- [ ] Hardcoded secrets or credentials
- [ ] `eval()` or `exec()` with user input
- [ ] Pickle with untrusted data
- [ ] SQL string concatenation (injection risk)
- [ ] YAML `yaml.load()` without `Loader=SafeLoader`

### Bugs (CRITICAL)
- [ ] Mutable default arguments (`def f(items=[])`)
- [ ] Bare `except:` clauses (swallows everything including KeyboardInterrupt)
- [ ] Missing `with` for file/connection handling (resource leaks)
- [ ] `==` comparison with `None` (use `is None`)
- [ ] Catching and silencing exceptions without logging

### Performance (WARNING)
- [ ] N+1 queries in loops
- [ ] Loading entire datasets into memory
- [ ] Synchronous I/O in async code
- [ ] Repeated regex compilation (compile once)

### For deep Python review → load `python` skill
### For K8s manifest review → load `k8s-security` skill
### For IAM policy review → load `aws-iam` skill

## Kubernetes Red Flags

### Security (CRITICAL)
- [ ] Missing or permissive `securityContext`
- [ ] Missing resource limits/requests
- [ ] `latest` tag usage
- [ ] `privileged: true`
- [ ] Secrets in env vars instead of volumes

### Reliability (WARNING)
- [ ] No `livenessProbe`/`readinessProbe`
- [ ] Single replica for production stateless apps
- [ ] No `PodDisruptionBudget`
- [ ] Missing anti-affinity / `topologySpreadConstraints`

## AWS Red Flags

### IAM (CRITICAL)
- [ ] `"Action": "*"` or `"Resource": "*"`
- [ ] Cross-account trust without external ID
- [ ] Long-lived access keys

### Infrastructure (WARNING)
- [ ] Public S3 buckets
- [ ] Unencrypted storage
- [ ] Security groups with `0.0.0.0/0`
- [ ] Missing CloudTrail/logging

## Completeness Check (Pre-Merge)

Before approving or declaring "done":

### Code Complete
- [ ] All acceptance criteria met
- [ ] Error paths handled (not just happy path)
- [ ] Edge cases addressed (empty inputs, nulls, large data)
- [ ] Tests written and passing
- [ ] No TODO/FIXME/HACK left without a ticket

### Operational Complete
- [ ] Config changes applied to all environments
- [ ] Migration scripts present if schema changed
- [ ] Logging/monitoring added for new features
- [ ] Rollback plan documented (if needed)
- [ ] Documentation updated (if user-facing change)

### Deployment Complete
- [ ] CI pipeline green
- [ ] No unrelated test failures introduced
- [ ] Feature flags configured (if applicable)
- [ ] Downstream dependencies notified (if API change)

## Output Format

```
CRITICAL: [issue]
   Impact: [what breaks]
   Fix: [concrete action]

WARNING: [issue]
   Risk: [consequence]
   Consider: [alternative]

SMELL: [issue]
   Cost: [future pain]
```

## Questions to Always Ask

1. What happens when this fails at 3am?
2. What happens at 10x traffic?
3. What's the blast radius if credentials leak?
4. What breaks during a rolling update?
5. What costs money when idle?
6. Can a new team member understand this in 5 minutes?
