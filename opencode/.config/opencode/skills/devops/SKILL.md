---
name: devops
description: 'CI/CD, Infrastructure as Code, containers, GitOps, monitoring, and release strategies. Triggers on "CI/CD", "pipeline", "terraform", "docker", "dockerfile", "github actions", "gitops", "monitoring", "incident".'
---

# DevOps Skill

## CI/CD — GitHub Actions

### Workflow Structure
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -e ".[test]"
      - run: pytest --tb=short -q

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v4
      - run: uv run ruff check .
      - run: uv run ruff format --check .
```

### Key Patterns
```yaml
# Cache dependencies
- uses: actions/cache@v4
  with:
    path: ~/.cache/uv
    key: uv-${{ hashFiles('uv.lock') }}

# Matrix builds
strategy:
  matrix:
    python-version: ["3.11", "3.12", "3.13"]

# Conditional steps
- if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  run: ./deploy.sh

# Secrets
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

# Job dependencies
deploy:
  needs: [test, lint]
  if: github.ref == 'refs/heads/main'
```

### Reusable Workflows
```yaml
# .github/workflows/reusable-deploy.yml
on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      AWS_ROLE_ARN:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    permissions:
      id-token: write
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
      - run: ./deploy.sh ${{ inputs.environment }}
```

## Infrastructure as Code — Terraform

### Project Structure
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       └── terraform.tfvars
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── eks/
└── backend.tf
```

### State Management
```hcl
# backend.tf — always remote state
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

Rules:
- **Never** local state in team environments
- State locking via DynamoDB (AWS) or native (Terraform Cloud)
- Separate state files per environment
- Use `terraform plan` before every `apply`
- Review plan output — never auto-approve in production

### Module Patterns
```hcl
# modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags = merge(var.tags, { Name = "${var.name}-vpc" })
}

# modules/vpc/variables.tf
variable "cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "name" {
  type        = string
  description = "VPC name prefix"
}

variable "tags" {
  type    = map(string)
  default = {}
}

# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}
```

### Key Rules
- Pin provider versions: `required_providers { aws = { version = "~> 5.0" } }`
- Use `count` or `for_each` for conditional/multiple resources
- Never hardcode values — use variables with descriptions
- Tag everything for cost tracking
- Use `data` sources to reference existing resources
- `terraform fmt` and `terraform validate` in CI

## Container Best Practices — Dockerfile

### Multi-Stage Build (Python)
```dockerfile
# Build stage
FROM python:3.12-slim AS builder
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN pip install uv && uv sync --frozen --no-dev

# Runtime stage
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv /app/.venv
COPY src/ ./src/
ENV PATH="/app/.venv/bin:$PATH"
USER 1000:1000
EXPOSE 8000
CMD ["python", "-m", "myapp"]
```

### Dockerfile Rules
| Rule | Why |
|------|-----|
| Pin base image tags | Reproducibility (`python:3.12.3-slim`, not `python:latest`) |
| Multi-stage builds | Smaller images, no build tools in runtime |
| Non-root user | Security (`USER 1000:1000`) |
| `.dockerignore` | Exclude `.git`, `__pycache__`, `*.pyc`, `.env` |
| Order layers by change frequency | Cache efficiency (deps before code) |
| One process per container | Simplicity, scaling, logging |
| HEALTHCHECK instruction | Container orchestrator integration |
| No secrets in image | Use env vars or mounted secrets at runtime |

### Image Scanning
```bash
# Trivy (scan for vulnerabilities)
trivy image myapp:latest

# Grype
grype myapp:latest

# In CI
- uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    severity: CRITICAL,HIGH
```

## GitOps

### ArgoCD Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-manifests.git
    targetRevision: main
    path: apps/myapp/overlays/production
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### GitOps Principles
1. **Git is the source of truth** — all changes via PR
2. **Declarative** — describe desired state, not steps
3. **Automated reconciliation** — controller syncs cluster to git
4. **Audit trail** — git history = change history
5. **Pull-based** — controller pulls changes (not CI pushing)

### Repository Strategy
| Pattern | When |
|---------|------|
| App repo + config repo (separate) | Teams own app code, platform team owns infra |
| Monorepo (app + config together) | Small teams, simple deployments |
| Config repo per environment | Strict environment separation |

## Monitoring & Alerting

### Prometheus + Grafana Stack
```yaml
# ServiceMonitor (Prometheus Operator)
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
    - port: metrics
      interval: 15s
      path: /metrics
```

### Alert Rules
```yaml
groups:
  - name: myapp
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High 5xx error rate on {{ $labels.instance }}"

      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 1
        for: 10m
        labels:
          severity: warning
```

### Key Metrics to Monitor
| What | Metric | Alert Threshold |
|------|--------|----------------|
| Availability | `up` | == 0 for 1m |
| Error rate | `rate(5xx)` | > 5% for 5m |
| Latency p99 | `histogram_quantile(0.99, ...)` | > SLO for 10m |
| CPU | `container_cpu_usage_seconds_total` | > 80% for 15m |
| Memory | `container_memory_working_set_bytes` | > 85% for 10m |
| Disk | `kubelet_volume_stats_used_bytes` | > 90% |
| Pod restarts | `kube_pod_container_status_restarts_total` | increase > 3 in 1h |

## Release Strategies

| Strategy | Risk | Rollback Speed | Use When |
|----------|------|---------------|----------|
| Rolling update | Low | Medium (rollout undo) | Default for stateless |
| Blue/Green | Very low | Instant (switch LB) | Zero downtime required |
| Canary | Low | Fast (route traffic back) | Testing with real users |
| Feature flags | Lowest | Instant (toggle flag) | Decoupling deploy from release |
| Recreate | High | Slow (full redeploy) | Stateful apps, breaking schema changes |

### Canary with ArgoCD Rollouts
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: myapp
spec:
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: { duration: 5m }
        - setWeight: 30
        - pause: { duration: 5m }
        - setWeight: 60
        - pause: { duration: 5m }
      canaryService: myapp-canary
      stableService: myapp-stable
```

## Secret Management

| Tool | Use Case |
|------|----------|
| Kubernetes Secrets | Basic, in-cluster only (base64, not encrypted) |
| External Secrets Operator | Sync from AWS Secrets Manager / Vault |
| SOPS | Encrypt secrets in git (with KMS/AGE) |
| HashiCorp Vault | Dynamic secrets, PKI, advanced policies |
| AWS Secrets Manager | AWS-native, rotation support |

### External Secrets Operator Pattern
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: myapp-secrets
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: myapp/production/db
        property: password
```

## Incident Response

### Severity Levels
| Level | Definition | Response |
|-------|-----------|----------|
| SEV1 | Service down, all users affected | Immediate, all-hands |
| SEV2 | Major degradation, many users affected | Within 15 min |
| SEV3 | Minor issue, some users affected | Within 1 hour |
| SEV4 | Cosmetic, workaround exists | Next business day |

### Incident Flow
```
Detect → Triage → Mitigate → Resolve → Post-mortem
```

### Post-Mortem Template
```markdown
## Incident: [Title]
Date: YYYY-MM-DD
Duration: Xh Ym
Severity: SEV-N
Impact: [who/what was affected]

## Timeline
- HH:MM — Alert fired
- HH:MM — Engineer acknowledged
- HH:MM — Root cause identified
- HH:MM — Mitigation applied
- HH:MM — Resolved

## Root Cause
[What actually broke and why]

## Action Items
- [ ] [preventive measure] — Owner — Due date
```

## Anti-Patterns

| Anti-Pattern | Fix |
|-------------|-----|
| Manual deployments | CI/CD pipeline with automated tests |
| Snowflake servers | Infrastructure as Code |
| Secrets in code/env files | Secret manager + External Secrets Operator |
| No monitoring until outage | Monitoring from day 1 (even in dev) |
| Alerting on everything | Alert on symptoms (user impact), not causes |
| No runbooks | Document recovery steps for each alert |
| Testing in production (only) | Test in staging; canary in production |
| Long-lived feature branches | Trunk-based development + feature flags |
