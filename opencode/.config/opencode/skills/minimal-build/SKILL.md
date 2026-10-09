---
name: minimal-build
description: 'Build Python/K8s/AWS with minimal code. Every line is a liability. Triggers on "build", "implement", "add", "create", "deploy". Prioritizes deletion, reuse, and configuration over new code.'
---

# Minimal Build Skill

Implement features with absolute minimum code for Python, Kubernetes, AWS.

## Prime Directive

**Every line is a liability.** Delete before adding. Reuse before writing. Configure before coding.

## Decision Hierarchy

### 1. DELETE First
- Remove dead code, unused dependencies
- Simplify requirements to avoid code

### 2. CONFIGURE Second
- Use existing CLI flags, env vars
- Leverage tool defaults

### 3. REUSE Third
- Standard library over dependencies
- Existing project code over new

### 4. WRITE Last (minimal)
- One-liners over functions
- Functions over classes
- Composition over inheritance

## Python Minimalism

### DO
```python
# Use stdlib
from pathlib import Path  # not os.path
from dataclasses import dataclass  # not manual __init__
from functools import lru_cache  # not manual caching

# Use comprehensions
items = [x for x in data if x.valid]  # not loops

# Use context managers
with open(f) as f: ...  # not try/finally
```

### DON'T
```python
# Don't add utils.py with one function
# Don't create abstract base classes for one implementation
# Don't add type hints for obvious types
# Don't wrap stdlib in "helper" classes
```

### Prefer
- `uv` by default. Use Poetry only if the repo already requires it.
- `ruff` over flake8+black+isort (one tool)
- `pytest` over unittest (less boilerplate)
- `httpx` over requests (async-ready, modern)
- `pydantic` for validation (not manual checks)

## Kubernetes Minimalism

### DO
```yaml
# Use Deployment defaults
# Don't specify what matches defaults
spec:
  replicas: 1  # only if not default

# Use Kustomize over Helm for simple cases
# Use ConfigMaps for config, not env vars sprawl
```

### DON'T
```yaml
# Don't create CRDs for simple config
# Don't add operators when Jobs suffice
# Don't use Helm for < 5 manifests
# Don't create namespaces per-microservice
```

### Prefer
- `kubectl apply -k` over Helm for simple deploys
- `Deployment` over `StatefulSet` unless you need stable identity
- `Job` over custom controllers for batch work
- `ConfigMap` over Secrets for non-sensitive config

## AWS Minimalism

### DO
```python
# Use boto3 defaults
client = boto3.client('s3')  # not custom sessions for basic use

# Use managed services
# Lambda > ECS > EKS for simple workloads
```

### DON'T
```python
# Don't wrap boto3 in abstraction layers
# Don't create custom retry logic (use botocore)
# Don't build what AWS provides (SQS > custom queue)
```

### Prefer
- SSM Parameter Store over custom config
- Lambda over containers for event-driven
- S3 events over polling
- SQS/SNS over custom messaging
- CloudFormation/CDK outputs over hardcoded ARNs

## Output Format

```
Lines added: X
Lines removed: Y
Dependencies: [added/removed]
K8s resources: [added/removed]
AWS resources: [added/removed]
```

## Anti-patterns

- "We might need scaling" -> Start with 1 replica
- "Let me add monitoring" -> Use managed (CloudWatch, Prometheus operator)
- "Custom logging framework" -> Use stdlib logging + structured output
- "Wrapper around boto3" -> Just use boto3 directly
