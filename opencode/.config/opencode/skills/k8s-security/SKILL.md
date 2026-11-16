---
name: k8s-security
description: "Kubernetes security best practices for manifests and Helm charts. Use on 'k8s security', 'manifest audit', 'helm security review', 'pod hardening'."
---

# Kubernetes Security Skill

Security review for Kubernetes manifests and Helm charts. Focus on least privilege, isolation, and safe defaults.

## When to Use

- Review Kubernetes YAML manifests
- Audit Helm charts or rendered templates
- Check pod security hardening
- Validate RBAC and service accounts
- Assess network isolation and ingress exposure

## Process (Read-Only First)

1. Identify input type:
   - Raw manifests (YAML)
   - Helm chart (templates + values)
   - Rendered templates (`helm template` output)
2. If Helm chart:
   - Prefer `helm template` to render with provided values
   - Review both values and rendered output
3. Check for blockers, then warnings, then smells
4. Output findings using the format below

## Helm-Specific Guidance

### Render Safely
```bash
helm lint ./chart
helm template ./chart -f values.yaml
```

### Values Red Flags
- `image.tag: latest`
- `securityContext` omitted or empty
- `rbac.create: true` with cluster-wide rules
- `serviceAccount.create: true` without scoped RBAC
- `ingress.enabled: true` without TLS
- `extraEnv` or `env` containing plaintext secrets
- Namespace management without Pod Security Standards labels
- `podSecurityContext` or container `securityContext` disabled via values
- Dependencies pulled from untrusted registries

## Kubernetes Security Checklist

### Pod Security Context
- `runAsNonRoot: true`
- `runAsUser`/`runAsGroup` set to non-root
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: ["ALL"]`
- `seccompProfile.type: RuntimeDefault`
- `privileged: false`

### Container Image Hygiene
- No `:latest` tag
- Pin by digest for critical workloads
- `imagePullPolicy: IfNotPresent` unless immutable tags
- Use trusted registries only

### Resource Safety
- `resources.requests` and `resources.limits` present
- Avoid memory limits lower than requests
- Define `startupProbe` for slow-start apps

### Networking
- `NetworkPolicy` present (ingress + egress)
- Ingress uses TLS and has hostnames
- Services avoid `type: LoadBalancer` unless required
- No open NodePort

### Policy Enforcement
- Pod Security Standards enforced at namespace level
- Admission control via Gatekeeper or Kyverno for critical controls
- Avoid deprecated `PodSecurityPolicy` (removed in K8s 1.25)

### Namespace and Quotas
- Namespace labels include ownership/team
- `ResourceQuota` and `LimitRange` for multi-tenant clusters
- Default deny policy for new namespaces

### Secrets Handling
- No plaintext secrets in env vars or values files
- Use `Secret` volumes or external secret managers
- Avoid `envFrom` with broad ConfigMaps

### RBAC and Service Accounts
- `serviceAccountName` specified
- RBAC scoped to namespace
- No `cluster-admin` bindings
- Avoid `automountServiceAccountToken: true` unless needed

### Storage
- Persistent volumes use encrypted storage class
- `fsGroup` set when needed
- Avoid hostPath unless explicitly required

## Common Findings

### Critical
- Privileged containers or `hostPID`/`hostNetwork` without justification
- Cluster-wide RBAC for app-level workloads
- Public ingress without TLS
- Admission policies missing for regulated workloads

### Warning
- Missing `securityContext`
- No NetworkPolicy
- `latest` image tags
- Missing resource requests/limits
- Namespace lacks Pod Security Standards labels

### Smell
- Overly permissive RBAC verbs (`*`)
- Secrets exposed via env vars
- Multiple containers sharing writable root filesystem
- No ResourceQuota or LimitRange in shared namespaces

## Reference Patterns

### Pod Security Standards (Namespace Labels)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: restricted-ns
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### NetworkPolicy Default Deny
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

### NetworkPolicy Allow DNS
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: kube-system
      ports:
        - protocol: UDP
          port: 53
```

### RBAC Self-Check (Read-Only)
```bash
kubectl auth can-i list pods --as system:serviceaccount:default:my-sa
```

## Output Format

```
CRITICAL: [issue]
   Impact: [what breaks]
   Fix: [action]

WARNING: [issue]
   Risk: [consequence]
   Fix: [action]

SMELL: [issue]
   Cost: [future pain]
```

## Notes

- Prefer minimal changes that improve security without breaking workloads
- If chart values are missing, ask for `values.yaml` or the rendered output
- When in doubt, suggest scoped, reversible changes
