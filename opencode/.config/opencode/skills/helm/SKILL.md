---
name: helm
description: "Helm chart policies, bitnami legacy repo, and release management. Use on 'helm-skill' or 'load helm skill'."
---

# Helm Skill

Helm chart management with safety and minimal footprint.

## Chart Repo Policy

### Critical: Bitnami Retired
**DO NOT use `bitnami/*` - the public repo was retired.** Use `bitnamilegacy/*` instead.

```bash
# WRONG
helm repo add bitnami https://charts.bitnami.com/bitnami  # DEAD REPO

# CORRECT
helm repo add bitnamilegacy https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami
```

### Bitnami Image Registry Override

Bitnami charts still work, but their Docker images moved registries.
**Always override the image registry in values:**

```yaml
# Global override (most charts)
global:
  imageRegistry: docker.io/bitnami

# Or use the legacy images explicitly
image:
  registry: docker.io
  repository: bitnami/mysql  # or bitnamilegacy/mysql for older versions
```

Common patterns:
```yaml
# mysql chart
image:
  registry: docker.io
  repository: bitnami/mysql

# redis chart
image:
  registry: docker.io
  repository: bitnami/redis

# For charts that need legacy images (check if current bitnami/* works first)
image:
  registry: docker.io
  repository: bitnamilegacy/mysql
```

**Note:** Test with current `bitnami/*` images first; only fall back to `bitnamilegacy/*` if the image is unavailable.

### Preferred Chart Sources

| Application | Source |
|-------------|--------|
| Airflow | `apache-airflow/airflow` |
| MinIO | `minio/operator` or official MinIO chart |
| MySQL | Official mysql chart or `bitnamilegacy/mysql` |
| Redis | `bitnamilegacy/redis` |
| PostgreSQL | `bitnamilegacy/postgresql` |
| Ingress | `ingress-nginx/ingress-nginx` |

## Command Safety

### Safe (Read-only)
```bash
helm template <chart>    # Render locally
helm lint <chart>        # Validate
helm show values <chart> # View defaults
helm list -A             # List releases
helm status <release>    # Check status
helm get values <rel>    # Current values
helm get manifest <rel>  # Deployed manifests
helm history <release>   # Release history
```

### Destructive (Require Approval)
```bash
helm install ...    # Creates resources
helm upgrade ...    # Modifies resources
helm uninstall ...  # Deletes resources
helm rollback ...   # Reverts release
```

## Workflow

### 1. Validate Before Install
```bash
helm lint ./chart                           # Check syntax
helm template ./chart -f values.yaml        # Render and review
helm template ./chart -f values.yaml | kubectl apply --dry-run=client -f -
```

### 2. Install/Upgrade
```bash
helm upgrade --install <release> <chart> \
  -n <namespace> --create-namespace \
  -f values.yaml \
  --wait --timeout 5m
```

### 3. Verify
```bash
helm list -n <namespace>
helm status <release> -n <namespace>
kubectl get pods -n <namespace>
```

## Values Management

### Override Hierarchy
1. Chart defaults (`helm show values`)
2. Base values file (`values.yaml`)
3. Environment overlay (`values-dev.yaml`, `values-prod.yaml`)
4. CLI `--set` flags (avoid for secrets)

### Values Pattern
```yaml
# values-dev.yaml
replicaCount: 1
resources:
  requests:
    memory: 256Mi
    cpu: 100m

# values-prod.yaml  
replicaCount: 3
resources:
  requests:
    memory: 1Gi
    cpu: 500m
```

### Secrets Pattern
- Use External Secrets Operator or Sealed Secrets
- Never commit plaintext secrets in values files
- Reference K8s secrets, don't inline values

## Debugging

### Release Issues
```bash
helm history <release>             # See revisions
helm get values <release>          # Current values
helm get manifest <release>        # What's deployed
helm rollback <release> <rev>      # Revert if needed
```

### Pod Issues
```bash
kubectl get pods -l app.kubernetes.io/instance=<release>
kubectl describe pod <pod>
kubectl logs <pod>
```

## Helm vs Kustomize

| Use Helm When | Use Kustomize When |
|---------------|-------------------|
| Complex app with many options | < 5 manifests |
| Upstream chart exists | Custom resources |
| Need templating/conditionals | Simple overlays |
| Want release management | GitOps with ArgoCD |

## ArgoCD Integration

```yaml
# ArgoCD Application for Helm
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    repoURL: https://charts.example.com
    chart: myapp
    targetRevision: 1.2.3
    helm:
      valueFiles:
        - values.yaml
        - values-prod.yaml
```

## Chart Authoring

### Chart Structure
```
mychart/
├── Chart.yaml              # Chart metadata and dependencies
├── values.yaml             # Default values
├── templates/
│   ├── _helpers.tpl        # Template helpers (partials)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml
│   └── NOTES.txt           # Post-install instructions
├── charts/                 # Subcharts (dependencies)
└── .helmignore
```

### Chart.yaml
```yaml
apiVersion: v2
name: mychart
version: 0.1.0          # Chart version (bump on every change)
appVersion: "1.0.0"     # App version
description: My application chart
type: application        # or "library"
dependencies:
  - name: postgresql
    version: "~15.0"
    repository: https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami
    condition: postgresql.enabled
```

### _helpers.tpl Patterns
```yaml
{{/*
Common name for resources
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fullname with release
*/}}
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "mychart.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Standard labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mychart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

### Values Design
```yaml
# values.yaml — design for usability
replicaCount: 1

image:
  repository: myapp
  tag: ""          # defaults to Chart.appVersion
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

postgresql:
  enabled: false    # subchart toggle
```

### Conditional Resources
```yaml
# templates/ingress.yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "mychart.fullname" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
  {{- with .Values.ingress.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  ...
{{- end }}
```

### Hooks
```yaml
# templates/pre-upgrade-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "mychart.fullname" . }}-migrate
  annotations:
    "helm.sh/hook": pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: migrate
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
          command: ["python", "-m", "alembic", "upgrade", "head"]
```

Hook types: `pre-install`, `post-install`, `pre-upgrade`, `post-upgrade`, `pre-delete`, `post-delete`, `pre-rollback`, `post-rollback`

### Subchart Dependencies
```bash
# Download dependencies
helm dependency update ./mychart
helm dependency build ./mychart

# Override subchart values
postgresql:
  auth:
    postgresPassword: "secret"
  primary:
    persistence:
      size: 10Gi
```

## Testing Charts

```bash
# Lint
helm lint ./mychart
helm lint ./mychart -f values-prod.yaml

# Template rendering (catch errors before deploy)
helm template myrelease ./mychart -f values.yaml

# Dry run against cluster (validates with API server)
helm install myrelease ./mychart --dry-run --debug

# helm-unittest plugin
helm unittest ./mychart

# kubeconform validation
helm template myrelease ./mychart | kubeconform -strict
```

## Helm Diff Plugin

```bash
# Install
helm plugin install https://github.com/databus23/helm-diff

# Preview changes before upgrade
helm diff upgrade myrelease ./mychart -f values.yaml -n ns

# Compare revisions
helm diff revision myrelease 1 2
```

Always run `helm diff` before `helm upgrade` in production.

## Quick Reference

```bash
# Add repos
helm repo add apache-airflow https://airflow.apache.org
helm repo add minio https://operator.min.io
helm repo add bitnamilegacy https://raw.githubusercontent.com/bitnami/charts/archive-full-index/bitnami
helm repo update

# Search
helm search repo <keyword>
helm search hub <keyword>

# Install from repo
helm upgrade --install myapp repo/chart -f values.yaml -n ns --create-namespace

# Install from local
helm upgrade --install myapp ./chart -f values.yaml -n ns
```
