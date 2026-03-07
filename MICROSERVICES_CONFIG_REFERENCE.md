# Microservices Architecture - Configuration Reference

## System Overview

Three-tier microservices architecture with Linkerd service mesh on EKS:

```
┌────────────────────────────────────────────────────────────────┐
│                         EKS Cluster                            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Linkerd Service Mesh & mTLS                 │  │
│  │                                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Frontend-UI  │  │    API       │  │   Database   │   │  │
│  │  │  (Namespace: │  │ (Namespace:  │  │ (Namespace:  │   │  │
│  │  │ frontend-ui) │  │ api-middle   │  │  backend-    │   │  │
│  │  │   Nginx      │  │   httpbin    │  │  database)   │   │  │
│  │  │   Port 80    │──│   Port 80    │──│  PostgreSQL  │   │  │
│  │  │  3 Replicas  │  │  3 Replicas  │  │   Port 5432  │   │  │
│  │  │              │  │              │  │ 1 StatefulSet│   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │       HPA 2-10          HPA 2-10         HPA 1-3        │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           ArgoCD (GitOps Controller)                     │  │
│  │  - Monitors GitOps repository                            │  │
│  │  - Automatically syncs applications                      │  │
│  │  - Manages application lifecycle                         │  │
│  └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
         ↑
         │ (Reads manifests from)
    GitOps Repository
```

## Deployment Summary

### 1. Frontend-UI Application

**Location**: `gitops/apps/frontend-ui/`

**Files**:
- `app.yaml` - ArgoCD Application CRD
- `manifests.yaml` - Kubernetes deployment resources
- `README.md` - Service documentation

**Specifications**:
```yaml
Kind: Deployment
Replicas: 3
Image: nginx:1.24-alpine
Port: 80
Namespace: frontend-ui
Service Type: ClusterIP
Security: fsGroup 101
```

**Resource Allocation**:
| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 100m | 200m |
| Memory | 64Mi | 128Mi |

**Auto-Scaling**:
- Min Replicas: 2
- Max Replicas: 10
- CPU Threshold: 70%
- Memory Threshold: 80%

**Health Checks**:
- Liveness: HTTP GET / (10s delay, 10s period)
- Readiness: HTTP GET / (5s delay, 5s period)

---

### 2. API-Middleware Application

**Location**: `gitops/apps/api-middleware/`

**Files**:
- `app.yaml` - ArgoCD Application CRD
- `manifests.yaml` - Kubernetes deployment resources
- `README.md` - Service documentation

**Specifications**:
```yaml
Kind: Deployment
Replicas: 3
Image: kennethreitz/httpbin:latest
Port: 80
Namespace: api-middleware
Service Type: ClusterIP
Security: Non-root (uid 1000)
```

**Resource Allocation**:
| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 200m | 500m |
| Memory | 128Mi | 256Mi |

**Auto-Scaling**:
- Min Replicas: 2
- Max Replicas: 10
- CPU Threshold: 75%
- Memory Threshold: 80%

**Health Checks**:
- Liveness: HTTP GET /get (15s delay, 10s period)
- Readiness: HTTP GET /get (10s delay, 5s period)

**Endpoints** (httpbin):
- GET /get
- POST /post
- PUT /put
- DELETE /delete
- PATCH /patch
- GET /headers
- GET /ip
- GET /status/{code}
- GET /delay/{seconds}

---

### 3. Backend-Database Application

**Location**: `gitops/apps/backend-database/`

**Files**:
- `app.yaml` - ArgoCD Application CRD
- `manifests.yaml` - Kubernetes deployment resources
- `README.md` - Service documentation

**Specifications**:
```yaml
Kind: StatefulSet
Replicas: 1
Image: postgres:15-alpine
Port: 5432
Namespace: backend-database
Service Type: ClusterIP (Headless)
Security: PostgreSQL user (uid 999)
Storage: 20Gi EBS (gp2)
```

**Resource Allocation**:
| Resource | Request | Limit |
|----------|---------|-------|
| CPU | 250m | 1000m |
| Memory | 256Mi | 512Mi |
| Storage | 20Gi | - |

**Auto-Scaling**:
- Min Replicas: 1
- Max Replicas: 3
- CPU Threshold: 80%

**Health Checks**:
- Liveness: `pg_isready -U postgres` (30s delay, 10s period)
- Readiness: `pg_isready -U postgres` (15s delay, 5s period)

**Configuration**:
| Variable | Value | Type |
|----------|-------|------|
| POSTGRES_DB | microservices_db | ConfigMap |
| POSTGRES_USER | postgres | ConfigMap |
| POSTGRES_PASSWORD | SecurePassword123!Change | Secret |

---

## Namespace Configuration

All three namespaces are configured with Linkerd injection:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: <namespace>
  labels:
    linkerd.io/inject: enabled  # Enables automatic sidecar injection
```

This enables automatic Linkerd sidecar proxy injection for all pods in these namespaces.

---

## ArgoCD Configuration

**Common Settings for All Applications**:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repository
    targetRevision: main
    path: gitops/apps/<app-name>
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true       # Delete out-of-sync resources
      selfHeal: true    # Re-sync on drift
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

---

## Service Mesh Integration

### Linkerd Annotations

All pods are automatically injected with Linkerd sidecars due to namespace annotation:

```yaml
metadata:
  annotations:
    linkerd.io/inject: enabled
```

### Service DNS Names

Applications can communicate using Kubernetes DNS:

**Frontend-UI to API-Middleware**:
```
http://api-middleware.api-middleware.svc.cluster.local:80
```

**API-Middleware to Database**:
```
postgresql://postgres:PASSWORD@backend-database.backend-database.svc.cluster.local:5432/microservices_db
```

### Linkerd Features Enabled

- **Automatic mTLS**: All service-to-service communication is encrypted
- **Service Discovery**: Built-in DNS resolution through Kubernetes
- **Traffic Metrics**: Real-time metrics collection
- **Reliability**: Automatic retries and timeouts
- **Security**: Zero-trust networking

---

## Deployment Workflow

```
1. Update GitOps Repository
   └─> Push changes to main branch

2. ArgoCD Detects Changes
   └─> Polls repository every 3 minutes (default)

3. ArgoCD Applies Manifests
   └─> Creates/updates Kubernetes resources

4. Kubernetes Deploys Pods
   ├─> Application container
   └─> Linkerd sidecar proxy

5. Linkerd Secures Communication
   └─> mTLS between services

6. ArgoCD Monitors Status
   └─> Reports sync status
```

---

## File Structure Reference

```
gitops-repository/
├── deploy.sh                          # Deployment automation script
├── DEPLOYMENT_GUIDE.md                # This comprehensive guide
├── gitops/
│   └── apps/
│       ├── README.md                  # Architecture overview
│       ├── frontend-ui/
│       │   ├── app.yaml              # ArgoCD Application
│       │   ├── manifests.yaml        # K8s Deployment, Service, HPA
│       │   └── README.md             # Service documentation
│       ├── api-middleware/
│       │   ├── app.yaml              # ArgoCD Application
│       │   ├── manifests.yaml        # K8s Deployment, Service, HPA
│       │   └── README.md             # Service documentation
│       └── backend-database/
│           ├── app.yaml              # ArgoCD Application
│           ├── manifests.yaml        # K8s StatefulSet, Service, HPA, PVC, Secret, ConfigMap
│           └── README.md             # Service documentation
```

---

## Quick Reference Commands

### View Applications
```bash
kubectl get applications -n argocd
argocd app list
```

### View Pod Status
```bash
kubectl get pods -n frontend-ui
kubectl get pods -n api-middleware
kubectl get pods -n backend-database
```

### Port Forward to Services
```bash
# Frontend UI
kubectl port-forward -n frontend-ui svc/frontend-ui 8080:80

# API Middleware
kubectl port-forward -n api-middleware svc/api-middleware 8081:80

# Database
kubectl port-forward -n backend-database svc/backend-database 5432:5432
```

### View Service Mesh Metrics
```bash
linkerd viz dashboard
linkerd viz stat namespaces
linkerd viz top -n frontend-ui
linkerd viz edges -A
```

### View Logs
```bash
kubectl logs -n frontend-ui -l app=frontend-ui -f
kubectl logs -n api-middleware -l app=api-middleware -f
kubectl logs -n backend-database -l app=backend-database -f
```

### Manually Trigger Sync
```bash
argocd app sync frontend-ui
argocd app sync api-middleware
argocd app sync backend-database
```

---

## Important Notes

### Database Password ⚠️
The default PostgreSQL password is `SecurePassword123!Change`. **Change this immediately in production** by updating the Secret:

```bash
kubectl edit secret -n backend-database postgres-secret
```

### Repository URL ⚠️
All `app.yaml` files reference `https://github.com/your-org/gitops-repository`. Update this to your actual repository URL before deployment.

### Storage Class ⚠️
Backend database uses `gp2` (AWS EBS). Update `storageClassName` in the PersistentVolumeClaim if using a different storage backend.

### Image Tags ⚠️
Images use generic tags (latest, latest). In production, use specific version tags for reproducibility.

---

## Best Practices Implemented

✅ **High Availability**
- Multiple replicas per service
- Horizontal Pod Autoscaling
- Pod Disruption Budgets (consider adding)

✅ **Health Checks**
- Liveness probes
- Readiness probes

✅ **Resource Management**
- CPU and memory requests
- CPU and memory limits

✅ **Security**
- Linkerd mTLS
- Non-root containers (API & DB)
- Secrets for sensitive data

✅ **Observability**
- Linkerd metrics collection
- Service mesh visibility
- Structured logging support

✅ **Infrastructure as Code**
- ArgoCD GitOps workflow
- Declarative manifests
- Version control

---

## Next Steps for Production

1. **Update Credentials**
   - Change database password
   - Store secrets in vault (AWS Secrets Manager, HashiCorp Vault)

2. **Configure Ingress**
   - Add Ingress Controller
   - Configure TLS certificates
   - Enable external access

3. **Set Up Monitoring**
   - Prometheus for metrics
   - Grafana for dashboards
   - Alerting rules

4. **Configure Backups**
   - PostgreSQL backup strategy
   - Backup retention policy
   - Restore testing

5. **Security Hardening**
   - Network Policies
   - Pod Security Policies
   - RBAC roles

6. **Multi-Region Setup**
   - Cross-cluster communication
   - Disaster recovery
   - Failover strategy

7. **Documentation**
   - Runbooks for operations
   - Disaster recovery procedures
   - Troubleshooting guides
