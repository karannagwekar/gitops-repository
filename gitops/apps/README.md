# Microservices Architecture

This directory contains 3 independent microservices applications designed to work with ArgoCD and Linkerd service mesh on EKS.

## Applications Overview

### 1. Frontend-UI (`frontend-ui/`)
- **Purpose**: Web user interface
- **Tech Stack**: Nginx 1.24-alpine
- **Port**: 80 (HTTP)
- **Replicas**: 3 (auto-scaled 2-10)
- **Namespace**: `frontend-ui` with Linkerd injection enabled
- **Resources**: Requests: 100m CPU, 64MB RAM | Limits: 200m CPU, 128MB RAM

### 2. API-Middleware (`api-middleware/`)
- **Purpose**: REST API and middleware services
- **Tech Stack**: Python httpbin
- **Port**: 80 (HTTP)
- **Replicas**: 3 (auto-scaled 2-10)
- **Namespace**: `api-middleware` with Linkerd injection enabled
- **Resources**: Requests: 200m CPU, 128MB RAM | Limits: 500m CPU, 256MB RAM

### 3. Backend-Database (`backend-database/`)
- **Purpose**: PostgreSQL database backend
- **Tech Stack**: PostgreSQL 15-alpine
- **Port**: 5432 (PostgreSQL)
- **Replicas**: 1 StatefulSet (auto-scaled to 3 max)
- **Namespace**: `backend-database` with Linkerd injection enabled
- **Storage**: 20GB persistent volume (gp2)
- **Resources**: Requests: 250m CPU, 256MB RAM | Limits: 1000m CPU, 512MB RAM

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Linkerd Service Mesh                 │
│                                                         │
│  ┌──────────────┐      ┌──────────────┐     ┌────────┐ │
│  │ Frontend-UI  │──────│ API-Middleware────│Database│ │
│  │   (Nginx)    │      │   (httpbin)  │     │(PgSQL) │ │
│  │  Port 80     │      │  Port 80     │     │ Port   │ │
│  │ 3 Replicas   │      │ 3 Replicas   │     │ 5432   │ │
│  └──────────────┘      └──────────────┘     └────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
         ↑
         │
    ArgoCD Sync
```

## Deployment Instructions

### Prerequisites
- EKS cluster running Kubernetes 1.25+
- ArgoCD v2.x deployed
- Linkerd 2.13+ installed on the cluster
- kubectl configured to access your EKS cluster

### Step 1: Update GitOps Repository Reference
Edit each `app.yaml` file and replace `https://github.com/your-org/gitops-repository` with your actual repository URL:

```bash
sed -i 's|https://github.com/your-org/gitops-repository|YOUR_REPO_URL|g' */app.yaml
```

### Step 2: Deploy Applications via ArgoCD

Apply all three applications to ArgoCD:

```bash
# Deploy all three apps
kubectl apply -f gitops/apps/frontend-ui/app.yaml
kubectl apply -f gitops/apps/api-middleware/app.yaml
kubectl apply -f gitops/apps/backend-database/app.yaml

# Or use ArgoCD CLI
argocd app create frontend-ui --repo <repo-url> --path gitops/apps/frontend-ui --dest-server https://kubernetes.default.svc --dest-namespace default
argocd app create api-middleware --repo <repo-url> --path gitops/apps/api-middleware --dest-server https://kubernetes.default.svc --dest-namespace default
argocd app create backend-database --repo <repo-url> --path gitops/apps/backend-database --dest-server https://kubernetes.default.svc --dest-namespace default
```

### Step 3: Verify Linkerd Injection

After deployment, verify that Linkerd sidecars are injected:

```bash
# Check Frontend-UI
kubectl get pods -n frontend-ui -o jsonpath='{.items[*].spec.containers[*].name}' | grep -i linkerd

# Check API-Middleware
kubectl get pods -n api-middleware -o jsonpath='{.items[*].spec.containers[*].name}' | grep -i linkerd

# Check Backend-Database
kubectl get pods -n backend-database -o jsonpath='{.items[*].spec.containers[*].name}' | grep -i linkerd
```

### Step 4: Verify Services

```bash
# Check all services
kubectl get svc -n frontend-ui
kubectl get svc -n api-middleware
kubectl get svc -n backend-database

# Test connectivity between services
kubectl port-forward -n frontend-ui svc/frontend-ui 8080:80 &
kubectl port-forward -n api-middleware svc/api-middleware 8081:80 &
kubectl port-forward -n backend-database svc/backend-database 5432:5432 &
```

## Monitoring with Linkerd

### View Mesh Topology
```bash
linkerd viz edges -A
linkerd viz top -n frontend-ui
linkerd viz stat -n api-middleware
linkerd viz routes -n backend-database
```

### Check Traffic Metrics
```bash
# Check success rate and latency
linkerd viz stat namespaces
linkerd viz stat ns -n frontend-ui --from linkerd
```

## Customization

### Scaling
Each service has HorizontalPodAutoscaler defined. Adjust thresholds in `manifests.yaml`:

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 70  # Adjust this value
```

### Database Configuration
For Backend-Database, update credentials in `backend-database/manifests.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
stringData:
  POSTGRES_PASSWORD: "YourNewSecurePassword"
```

### Image Updates
To use different images, update the `image` field in respective manifests:

```yaml
containers:
- name: frontend-ui
  image: your-registry/your-frontend:v1.0.0
```

## Storage (Backend-Database)

The PostgreSQL database uses:
- **StorageClass**: gp2 (AWS EBS)
- **Size**: 20Gi
- **Mount Path**: /var/lib/postgresql/data

To use different storage:
1. Change `storageClassName` in PersistentVolumeClaim
2. Adjust storage `requests` as needed

## Networking

Each namespace has `linkerd.io/inject: enabled` label, which automatically injects Linkerd sidecars to all pods. All services use ClusterIP (internal communication only).

To expose services externally, add an Ingress or LoadBalancer service.

## Security Considerations

- Frontend-UI: Runs as root (fs group 101)
- API-Middleware: Runs as non-root user (uid 1000)
- Backend-Database: Runs as postgres user (uid 999)
- Database password stored in Kubernetes Secret
- Service mesh provides mTLS for all inter-service communication

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod -n frontend-ui
kubectl logs -n frontend-ui --all-containers=true
```

### Database connection issues
```bash
# Test database connection
kubectl exec -it -n backend-database backend-database-0 -- psql -U postgres -d microservices_db -c "SELECT 1;"
```

### Linkerd sidecar not injected
```bash
# Check namespace label
kubectl get ns frontend-ui -o yaml | grep linkerd

# Manually inject for a deployment
linkerd inject gitops/apps/frontend-ui/manifests.yaml | kubectl apply -f -
```

## Next Steps

1. **Update repository URL** in each `app.yaml`
2. **Configure database credentials** for production
3. **Set resource limits** based on your workload
4. **Configure Linkerd policies** for traffic management
5. **Set up Ingress** for external access
6. **Implement backup strategy** for PostgreSQL data
7. **Configure monitoring** with Prometheus and Grafana
