---
name: k8s-troubleshoot
description: 'Systematic Kubernetes troubleshooting for pods, nodes, networking, storage, and control-plane issues. Triggers on "pod not starting", "crash loop", "OOMKilled", "debug k8s", "why is pod failing", "ImagePullBackOff", "CrashLoopBackOff", "kubectl describe".'
---

# Kubernetes Troubleshooting Skill

Systematic debugging for Kubernetes issues. Follow the diagnostic flow — don't guess.

## Diagnostic Flow

```
1. What's the symptom?  → Pod status / Events / Conditions
2. Where does it fail?  → Scheduling / Image / Init / Runtime / Network
3. Gather evidence      → describe, logs, events, exec
4. Root cause           → Fix the source, not the symptom
```

### Step 1: Get the Lay of the Land
```bash
kubectl get pods -o wide -n <ns>
kubectl get events --sort-by='.lastTimestamp' -n <ns>
kubectl describe pod <pod> -n <ns>
kubectl get nodes -o wide
```

### Step 2: Check Logs
```bash
kubectl logs <pod> -n <ns>                    # current container
kubectl logs <pod> -n <ns> --previous         # crashed container
kubectl logs <pod> -n <ns> -c <container>     # specific container
kubectl logs <pod> -n <ns> --all-containers   # all sidecars
stern <pod-prefix> -n <ns>                     # multiple pods (stern)
```

### Step 3: Resource Pressure
```bash
kubectl top pods -n <ns> --sort-by=memory
kubectl top nodes
kubectl describe node <node> | grep -A10 "Allocated resources"
kubectl describe node <node> | grep -A5 "Conditions"
```

## Pod Won't Start — Decision Tree

```
Pod status?
├── Pending
│   ├── Events say "Insufficient cpu/memory" → Node capacity / resource requests too high
│   ├── Events say "no nodes match" → nodeSelector/affinity/taint mismatch
│   ├── Events say "persistentvolumeclaim not found" → PVC missing or not bound
│   ├── Events say "0/N nodes available" → Check taints, quotas, node conditions
│   └── No events at all → Scheduler not running or ResourceQuota exhausted
├── Init:CrashLoopBackOff
│   └── Check init container logs: kubectl logs <pod> -c <init-container> --previous
├── ImagePullBackOff
│   ├── Image doesn't exist → Fix image:tag
│   ├── Private registry → Add/fix imagePullSecrets
│   └── Rate limited → Use mirror or pull-through cache
├── CrashLoopBackOff
│   ├── Exit code 1 → App error (check logs --previous)
│   ├── Exit code 127 → Command not found (bad entrypoint/command)
│   ├── Exit code 137 → OOMKilled (increase memory limit)
│   ├── Exit code 139 → Segfault (debug the app)
│   └── Logs empty → Container exits before logging (check command/args)
├── CreateContainerConfigError
│   └── ConfigMap or Secret referenced doesn't exist → Create it
├── RunContainerError
│   └── Volume mount failure → Check PVC, node storage, permissions
└── Running but not Ready
    └── Readiness probe failing → Check probe config and app health endpoint
```

## DNS Troubleshooting

```bash
# Test DNS resolution from inside a pod
kubectl exec -it <pod> -- nslookup kubernetes.default
kubectl exec -it <pod> -- nslookup <service>.<namespace>.svc.cluster.local

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# Test with a debug pod
kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3 \
  --restart=Never --rm -it -- nslookup <service>

# Full DNS format
<service>.<namespace>.svc.cluster.local
```

Common DNS issues:
| Symptom | Cause | Fix |
|---------|-------|-----|
| `NXDOMAIN` for service | Wrong service name or namespace | Check `kubectl get svc -A` |
| `SERVFAIL` | CoreDNS pods down or misconfigured | Restart CoreDNS, check ConfigMap |
| Intermittent DNS failures | CoreDNS resource pressure or ndots too high | Tune `dnsConfig.ndots` (set to 2) |
| DNS works from some pods | NetworkPolicy blocking DNS | Allow egress to `kube-dns` on port 53 |

## Ingress & cert-manager Troubleshooting

### Ingress
```bash
# Check ingress resource
kubectl get ingress -n <ns>
kubectl describe ingress <name> -n <ns>

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx

# Test backend directly
kubectl port-forward svc/<backend-service> 8080:80 -n <ns>
curl localhost:8080
```

| Symptom | Cause | Fix |
|---------|-------|-----|
| 404 from ingress | Path/host rule mismatch | Check `rules[].host` and `paths` |
| 502 Bad Gateway | Backend pod not ready or wrong port | Check Service targetPort matches container |
| 503 Service Unavailable | No endpoints | Check Service selector matches Pod labels |
| No address assigned | Ingress controller not running | Deploy/fix ingress controller |

### cert-manager
```bash
# Check certificate status
kubectl get certificates -A
kubectl describe certificate <name> -n <ns>

# Check certificate request
kubectl get certificaterequest -A
kubectl describe certificaterequest <name> -n <ns>

# Check orders and challenges
kubectl get orders -A
kubectl get challenges -A
kubectl describe challenge <name> -n <ns>

# cert-manager logs
kubectl logs -n cert-manager -l app.kubernetes.io/name=cert-manager
```

| Symptom | Cause | Fix |
|---------|-------|-----|
| Certificate stuck `False` | Challenge failing | Check challenge type (HTTP01/DNS01) |
| HTTP01 challenge fails | Ingress can't serve `.well-known/acme-challenge` | Check ingress class, port 80 open |
| DNS01 challenge fails | Missing DNS credentials or wrong zone | Check ClusterIssuer secret |
| Order stuck `pending` | Rate limited or invalid domain | Check Let's Encrypt logs, verify domain |

## Node Issues

```bash
# Node conditions
kubectl describe node <node> | grep -A20 "Conditions:"

# Check node readiness
kubectl get nodes -o wide

# Drain/cordon
kubectl cordon <node>          # prevent new scheduling
kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
```

| Condition | Meaning | Investigation |
|-----------|---------|--------------|
| `Ready=False` | Kubelet not healthy | SSH to node, check kubelet logs |
| `MemoryPressure` | Node low on memory | Check `kubectl top node`, eviction thresholds |
| `DiskPressure` | Node low on disk | Check `df -h` on node, clean images |
| `PIDPressure` | Too many processes | Check for fork bombs, container leaks |
| `NetworkUnavailable` | CNI plugin issue | Check CNI plugin pods (calico/flannel/cilium) |

## HPA / Autoscaling Issues

```bash
# Check HPA status
kubectl get hpa -n <ns>
kubectl describe hpa <name> -n <ns>

# Check metrics-server
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl top pods -n <ns>
```

| Symptom | Cause | Fix |
|---------|-------|-----|
| `<unknown>/80%` in targets | metrics-server not running or resource requests not set | Install metrics-server, set resource requests |
| Not scaling up | Already at maxReplicas or metric below threshold | Adjust max or target |
| Not scaling down | `stabilizationWindowSeconds` too long | Tune HPA behavior |
| Custom metrics `<unknown>` | Prometheus adapter misconfigured | Check adapter rules and Prometheus targets |

## Storage / PVC Issues

```bash
# Check PVC status
kubectl get pvc -n <ns>
kubectl describe pvc <name> -n <ns>

# Check PV
kubectl get pv
kubectl describe pv <name>

# Check storage class
kubectl get storageclass
```

| Symptom | Cause | Fix |
|---------|-------|-----|
| PVC stuck `Pending` | No PV available or StorageClass missing | Check StorageClass exists, provisioner running |
| PVC `Bound` but pod `Pending` | Volume access mode mismatch (ReadWriteOnce on multi-node) | Use ReadWriteMany or schedule to same node |
| Mount error in pod | Filesystem corruption or permissions | Check `fsGroup` in securityContext |
| Volume resize stuck | StorageClass doesn't allow expansion | Set `allowVolumeExpansion: true` |

## Network Policy Debugging

```bash
# List network policies
kubectl get networkpolicy -n <ns>
kubectl describe networkpolicy <name> -n <ns>

# Test connectivity between pods
kubectl exec -it <source-pod> -- wget -qO- --timeout=3 <target-service>:<port>
kubectl exec -it <source-pod> -- nc -zv <target-pod-ip> <port>
```

Step-by-step connectivity debugging:
1. Check if NetworkPolicies exist: `kubectl get netpol -n <ns>`
2. If yes — are they `deny-all`? (empty `spec.ingress`/`spec.egress`)
3. Do pod labels match the policy's `podSelector`?
4. Does the policy allow the specific port and protocol?
5. For egress — does it allow DNS (port 53 to kube-dns)?
6. Remove the NetworkPolicy temporarily to confirm it's the cause

## Webhook Debugging

```bash
# List validating/mutating webhooks
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations
kubectl describe validatingwebhookconfiguration <name>
```

| Symptom | Cause | Fix |
|---------|-------|-----|
| `context deadline exceeded` on create/apply | Webhook service unreachable | Check webhook pod running, cert valid |
| Resources silently modified | Mutating webhook changing values | `kubectl describe mutatingwebhookconfiguration` |
| Can't create resources after cert rotation | Webhook TLS cert expired | Rotate cert, restart webhook pod |

## kubectl debug (Ephemeral Containers)

```bash
# Debug running pod with ephemeral container
kubectl debug -it <pod> --image=busybox --target=<container>

# Debug node
kubectl debug node/<node> -it --image=busybox

# Copy pod and debug (non-destructive)
kubectl debug <pod> -it --copy-to=<pod>-debug --container=debugger --image=nicolaka/netshoot
```

## Quick Reference Commands

```bash
# All unhealthy pods
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded

# Recent events (last 1 hour)
kubectl get events -A --sort-by='.lastTimestamp' | tail -30

# Resource usage across cluster
kubectl top pods -A --sort-by=memory | head -20
kubectl top nodes

# Shell into pod
kubectl exec -it <pod> -n <ns> -- /bin/sh

# Port forward
kubectl port-forward svc/<service> 8080:80 -n <ns>

# Restart deployment
kubectl rollout restart deployment/<name> -n <ns>

# Rollout status
kubectl rollout status deployment/<name> -n <ns> --timeout=5m

# Rollback
kubectl rollout undo deployment/<name> -n <ns>

# Force delete stuck pod
kubectl delete pod <pod> -n <ns> --grace-period=0 --force

# Check cluster health
kubectl cluster-info
kubectl get componentstatuses 2>/dev/null || kubectl get --raw='/readyz?verbose'
```

## Log Patterns to Search

```bash
# Errors
kubectl logs <pod> -n <ns> | grep -i error

# Python tracebacks
kubectl logs <pod> -n <ns> | grep -A 20 "Traceback"

# OOM
kubectl logs <pod> -n <ns> | grep -i "out of memory\|oom\|killed"

# Connection issues
kubectl logs <pod> -n <ns> | grep -i "connection refused\|timeout\|ECONNRESET"

# Readiness/liveness failures
kubectl logs <pod> -n <ns> | grep -i "health\|ready\|alive\|probe"
```
