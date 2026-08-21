# GitHub Copilot

This repo uses the standalone `copilot` CLI with wrapper functions from `iron/.zshrc`. It does **not** use the legacy `gh copilot` extension workflow.

## Stowed config

```bash
cd ~/dotfiles
stow iron
```

That puts:

- `iron/.copilot/` at `~/.copilot/`
- `iron/.local/bin/` wrappers such as `aws-ics-dev` and `kubectl-ics-prod` on your PATH

`~/.copilot/` contains the shared Copilot setup:

```text
iron/.copilot/
├── agents/
├── skills/
└── mcp-config.json
```

## Launchers you actually use

All of these are zsh functions defined in `iron/.zshrc` and invoke `copilot` with a pinned tool/safety profile.

| Launcher | Use case |
|---|---|
| `gh-copilot` | Lightweight default profile; no MCP servers |
| `infra-copilot` | Infra troubleshooting with read-only AWS/Kubernetes/Helm/Docker/Terraform approvals |
| `sonar-copilot` | SonarQube-focused profile with Sonar tools enabled |
| `drawio-copilot` | Interactive draw.io-only diagram work |
| `azure-copilot` | Azure DevOps ticket and work-item management |
| `nexus-copilot` | Wrapper for `nexus-copilot:nexus` with infra access |
| `cc` | fzf picker for the main profiles |
| `drawio-copilot-task` / `copilot-drawio-task` | Non-interactive draw.io task launcher |
| `copilot-drawio-task-bash` | Same draw.io task flow via a fresh bash shell |

## Safety model

The wrappers intentionally start from a conservative baseline.

- MCP servers are disabled by default; profiles opt into only the tools they need.
- Runtime safety always includes:
  - `--disallow-temp-dir`
  - `--secret-env-vars=AWS_ACCESS_KEY_ID,AWS_SECRET_ACCESS_KEY,AWS_SESSION_TOKEN,AWS_SECURITY_TOKEN,GH_TOKEN,GITHUB_TOKEN,COPILOT_GITHUB_TOKEN`
- `~/.nexus-worktrees` is added as a trusted extra directory root, so file access under that tree is available without per-directory approval prompts.
- Default shell approvals are narrower than before. Commands such as `find`, `env`, `python`, `uv`, and `pytest` are **not** auto-approved.
- `nexus` is auto-approved in the Iron launchers so Nexus task-tracker flows do not stall on shell approval prompts.
- `gh` auto-approval stays read-only and conservative: `gh pr list`, `gh pr status`, `gh pr diff`, `gh pr checks`, and `gh pr view`.
- Raw `aws` and raw `kubectl` are explicitly denied.
- Cloud access should go through pinned wrappers:
  - `aws-ics-dev`
  - `aws-ics-prod`
  - `kubectl-ics-dev`
  - `kubectl-ics-prod`
- Prod auto-approval is granular and read-only. It is not a wildcard prod escape hatch.
- Draw.io launchers no longer use `--allow-all-tools`; they expose draw.io plus the minimum runtime behavior needed for the task.

The Azure DevOps profile enables the `azure-devops` MCP server for the `cat-aa`
organization and loads only the `core` and `work-items` domains.

## Cloud wrapper behavior

The wrapper scripts in `iron/.local/bin/` do more than rename commands:

- AWS wrappers scrub ambient credential overrides such as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, `AWS_PROFILE`, and related role/container overrides.
- Kubernetes wrappers also unset `KUBECONFIG`.
- Dev and prod wrappers pin the AWS profile or kube context directly.
- Override flags such as `--profile`, `--endpoint-url`, `--context`, `--kubeconfig`, and other connection/identity flags are blocked.
- Prod wrappers enforce read-only command families before the CLI is even invoked.

In practice: assume ambient credentials are not the interface. Use the pinned wrapper that matches the environment you need.

## Draw.io

The draw.io MCP server is configured in `iron/.copilot/mcp-config.json` and expects a local draw.io instance:

```bash
cd ~/dotfiles/ai
docker compose up -d
curl -f http://localhost:8098/
```

Use `drawio-copilot` for interactive diagram work, or `copilot-drawio-task "..."` for a one-shot diagram task.

## See also

- [OpenCode](opencode.md)
