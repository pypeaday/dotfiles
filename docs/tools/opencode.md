# OpenCode

Terminal-based AI coding assistant. Config managed with stow across multiple packages.

## Installation

```bash
cd ~/dotfiles
stow opencode  # Base config (permissions, MCP, skills, commands)
stow iron      # Work: GitHub Copilot models (requires subscription)
stow home      # Home: OpenCode Zen free models (no subscription needed)
```

Symlinks `~/.config/opencode/` to dotfiles. The `iron` and `home` packages overlay agent configs on the base `opencode` package.

## Structure

```
opencode/.config/opencode/
├── opencode.jsonc     # Config (models, permissions, MCP)
├── skill/             # Reusable skills
└── command/           # Slash commands

iron/.config/opencode/agent/    # Work agents (GitHub Copilot)
home/.config/opencode/agent/    # Home agents (OpenCode Zen free)
```

## Model Providers

### GitHub Copilot (`iron` package)

For work environments with GitHub Copilot subscription. Premium models, no per-token cost.

| Agent | Model | Rationale |
|-------|-------|-----------|
| `builder` | `github-copilot/gpt-5.2-codex` | Latest code-optimized model for complex implementations |
| `quick-fix` | `github-copilot/claude-haiku-4.5` | Fast, efficient for focused single-file edits |
| `researcher` | `github-copilot/claude-sonnet-4.5` | Deep reasoning for analysis and debugging |
| `reviewer-ro` | `github-copilot/claude-sonnet-4.5` | Thorough code review and security audit |
| `tester` | `github-copilot/gpt-5.2-codex` | Code-optimized for test generation |
| `task-orchestrator` | (default) | Coordination and delegation |
| `ideation-ro` | (default) | Creative exploration |

### OpenCode Zen (`home` package)

For personal environments without paid subscriptions. All models are **free** (cost: $0).

| Agent | Model | Rationale |
|-------|-------|-----------|
| `builder` | `opencode/grok-code` | Coding-focused, 256k context, free |
| `quick-fix` | `opencode/gpt-5-nano` | Fast, lightweight for simple edits, free |
| `researcher` | `opencode/big-pickle` | Reasoning capabilities, 200k context |
| `reviewer-ro` | `opencode/big-pickle` | Reasoning capabilities, 200k context |
| `tester` | `opencode/grok-code` | Coding-focused for test generation, free |
| `task-orchestrator` | `opencode/big-pickle` | Reasoning for coordination/delegation |
| `ideation-ro` | `opencode/big-pickle` | Reasoning capabilities for creativity |

### OpenCode Zen Models Reference

All available models via `opencode/` provider (API: `https://opencode.ai/zen/v1`):

| Model | Context | Pricing | Best For |
|-------|---------|---------|----------|
| `gpt-5-nano` | 400k | Free | Fast, lightweight tasks |
| `big-pickle` | 200k | Free | General reasoning, analysis |
| `grok-code` | 256k | Free | Coding tasks, large context |
| `minimax-m2.1-free` | 205k | Free | General reasoning |
| `glm-4.7` | 205k | Paid | Advanced reasoning with interleaved thinking |

Note: Invalid model identifiers like `glm-4.7-free` do not exist in the OpenCode Zen catalog. Always use the format `opencode/<model-id>` with valid model IDs listed above.

## Agents

### Primary Agents (User-Facing)

| Agent | Purpose |
|-------|---------|
| `ideation` | Brainstorming, creative exploration (read-only) |
| `task-orchestrator` | Aggressive delegation to builder/reviewer/tester subagents |

### Subagents (Delegated via Task)

| Agent | Purpose |
|-------|---------|
| `builder` | Complex multi-file implementations |
| `quick-fix` | Small one-off edits (docstrings, renames, imports) |
| `tester` | Test writing and validation |
| `researcher` | Complex multi-step analysis and debugging |
| `reviewer-ro` | Code review, security audit (read-only) |

```bash
opencode                            # Default agent
opencode --agent task-orchestrator  # Specific agent
# Tab to switch during session
```

## Model Strategy

The model choice per agent follows this philosophy:

- **Coding agents** (builder, tester): Use code-optimized models with large context
- **Speed agents** (quick-fix): Use fast, lightweight models for focused work
- **Reasoning agents** (researcher, reviewer, ideation): Use models with strong reasoning/analysis
- **Orchestration agents** (task-orchestrator): Use reasoning models for coordination

## Permissions

Defined in `opencode.jsonc`, but the effective shell surface also depends on the launcher profile. In the hardened work launchers, the default posture is narrower than "bash can do anything": repo inspection and selected local tooling are auto-approved, raw cloud CLIs are blocked, and infra access flows through pinned wrappers.

Example:

```yaml
permission:
  bash:
    "git status": "allow"
    "git diff*": "allow"
    "ls *": "allow"
    "aws *": "deny"
    "kubectl *": "deny"
    "aws-ics-dev ec2 describe-*": "allow"
    "aws-ics-prod ec2 describe-*": "allow"
    "kubectl-ics-dev get*": "allow"
    "kubectl-ics-prod get*": "allow"
    "git push*": "ask"
    "kubectl-ics-dev apply*": "ask"
    "tofu apply*": "ask"
    "rm *": "deny"
    "sudo *": "deny"
  edit:
    "**/*.env*": "ask"
    "**/*.key": "deny"
```

### Permission Levels

| Level | Behavior |
|-------|----------|
| `allow` | Execute without asking |
| `ask` | Prompt for approval |
| `deny` | Block completely |

In the hardened Iron/Copilot launchers, the wrapper commands also scrub ambient AWS credential overrides and reject profile/context override flags. Production wrappers are explicitly read-only and granular—they are not blanket `aws-ics-prod *` or `kubectl-ics-prod *` auto-approvals.

## Skills

Reusable knowledge modules loaded by agents:

| Skill | Purpose |
|-------|---------|
| `python-uv` | PEP 723 scripts, uv-first policy |
| `airflow` | DAG patterns, KubernetesPodOperator, version detection |
| `helm` | Chart management, bitnami legacy repo, image registry overrides |
| `k8s-troubleshoot` | Kubernetes debugging |
| `aws-iam` | IAM policy creation and debugging |
| `aws-infra` | AWS resource discovery via pinned wrappers and read-only CLI flows |
| `steampipe-aws` | AWS resource discovery via SQL |
| `code-review` | Ruthless review methodology |
| `minimal-build` | Build with minimal code |
| `progress-tracker` | SQLite-based task tracking |
| `git` | Git operations, commits, worktrees, safety protocols |
| `drawio` | Architecture diagrams via draw.io MCP and focused diagram helpers |
| `nexus-orchestrator` | Claim epics, decompose into subtasks, delegate to workers |
| `nexus-worker` | Claim and execute subtasks from nexus |

### Nexus Skills

The `nexus-orchestrator` and `nexus-worker` skills enable multi-agent task coordination via a local nexus server (port 7001).

**nexus-orchestrator** (for task-orchestrator agent):
1. Claim high-level issues (epics/features)
2. Explore scope with `explore` agent
3. Decompose into subtasks: `nexus issue create --parent <id> --title "..."`
4. Delegate subtasks to builder with `NEXUS SUBTASK: <id>` in prompt
5. Verify each subtask, then complete parent

**nexus-worker** (for builder/subagents):
1. Claim assigned subtask: `nexus issue claim <id>`
2. Implement focused changes
3. Complete when done: `nexus issue update <id> --status completed`

Key commands:
```bash
nexus status                                    # Check server/claims
nexus next --claim --format json               # Get next issue
nexus issue create --title "..." --parent <id> # Create subtask
nexus issue update <id> --status completed     # Complete issue
nexus issue renew <id>                         # Extend claim (20 min)
```

## MCP Servers

Disabled by default. Enable per-project in `opencode.jsonc`:

```jsonc
{
  "mcp": {
    "steampipe": { "enabled": true },
    "PieGPT": { "enabled": true }
  }
}
```

| Server | Purpose |
|--------|---------|
| `steampipe` | AWS/cloud queries (preferred) |
| `drawio` | Architecture diagrams; keep automation draw.io-scoped rather than general shell work |
| `PieGPT` | K8s ops (Avant) |
| `spacectl` | Spacelift (Avant) |
| `mcp-server-docker` | Docker operations |
| `git` | Git MCP server |
| `firefox-devtools` | Browser automation |

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/context` | Project discovery and analysis |
| `/commit` | Conventional commits with formatting |
| `/worktrees` | Git worktree management |

## Tips

1. Use `@quick-fix` for small edits, `@builder` for complex work
2. Use `@task-orchestrator` for multi-step features requiring coordination
3. Check `justfile` first for project commands
4. Use git worktrees for parallel work
5. Prefer Steampipe for AWS resource queries; in work launchers, use `aws-ics-dev`, `aws-ics-prod`, `kubectl-ics-dev`, and `kubectl-ics-prod` instead of raw `aws`/`kubectl`
6. Load skills explicitly when needed (e.g., "load python-uv skill")
7. Use `drawio` skill for architecture diagrams; the task helpers are intentionally draw.io-only, run with runtime safety flags, and do not grant `--allow-all-tools`
8. Switch environments: `stow -D iron && stow home` (or vice versa) to swap agent configs

## Customization

**Add agents:** Create `.md` files in `agent/`

**Add skills:** Create directories in `skill/` with `SKILL.md`

**Add commands:** Create `.md` files in `command/`

## See Also

- [Copilot](copilot.md) - GitHub Copilot (agent/skill parity for VS Code Copilot Chat)
- [VS Code](vscode.md) - VS Code setup
