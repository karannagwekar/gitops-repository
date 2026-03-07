# Microservices Quick Start Guide

## What Was Created

I've successfully created **3 production-ready microservices** in ArgoCD and Linkerd-compatible formats for your EKS cluster:

### 📦 The Three Microservices

1. **Frontend-UI** (`gitops/apps/frontend-ui/`)
   - Nginx web server
   - 3 replicas with autoscaling (2-10)
   - Namespace: `frontend-ui`

2. **API-Middleware** (`gitops/apps/api-middleware/`)
   - Python httpbin REST API
   - 3 replicas with autoscaling (2-10)
   - Namespace: `api-middleware`

3. **Backend-Database** (`gitops/apps/backend-database/`)
   - PostgreSQL 15
   - StatefulSet with persistent storage (20Gi)
   - Namespace: `backend-database`

All services are configured with:
✅ Linkerd service mesh injection enabled
✅ Horizontal Pod Autoscaling
✅ Health checks (liveness & readiness probes)
✅ Resource requests and limits
✅ ArgoCD deployment manifests

---

## 📋 File Structure Created

```
gitops-repository/
├── deploy.sh                          ← Run this for automated deployment
├── DEPLOYMENT_GUIDE.md                ← Comprehensive deployment instructions
├── MICROSERVICES_CONFIG_REFERENCE.md  ← Detailed configuration reference
└── gitops/apps/
    ├── frontend-ui/
    │   ├── app.yaml                  (ArgoCD Application CRD)
    │   ├── manifests.yaml             (K8s resources)
    │   └── README.md                  (Service details)
    ├── api-middleware/
    │   ├── app.yaml                  (ArgoCD Application CRD)
    │   ├── manifests.yaml             (K8s resources)
    │   └── README.md                  (Service details)
    └── backend-database/
        ├── app.yaml                  (ArgoCD Application CRD)
        ├── manifests.yaml             (K8s resources)
        └── README.md                  (Service details)
```

---

## 🚀 Quick Start (3 Steps)

### Step 1: Update Repository URL

Edit the repository URL in all three `app.yaml` files. Replace `https://github.com/your-org/gitops-repository` with your actual repository URL:

```bash
cd gitops-repository

# Update all app.yaml files
sed -i.bak 's|https://github.com/your-org/gitops-repository|YOUR_REPO_URL|g' gitops/apps/*/app.yaml

# Example:
# sed -i.bak 's|https://github.com/your-org/gitops-repository|https://github.com/mycompany/my-gitops-repo|g' gitops/apps/*/app.yaml
```

### Step 2: Deploy Using the Script

```bash
chmod +x deploy.sh
./deploy.sh https://github.com/your-org/gitops-repository
```

Or manually deploy:
```bash
kubectl apply -f gitops/apps/frontend-ui/app.yaml
kubectl apply -f gitops/apps/api-middleware/app.yaml
kubectl apply -f gitops/apps/backend-database/app.yaml
```

### Step 3: Verify Deployment

```bash
# Check deployments
kubectl get applications -n argocd

# Wait for pods to be ready
kubectl get pods -n frontend-ui -w
kubectl get pods -n api-middleware -w
kubectl get pods -n backend-database -w

# Verify Linkerd injection
linkerd check
```

---

## 🧪 Testing the Deployment

### Test Frontend-UI
```bash
kubectl port-forward -n frontend-ui svc/frontend-ui 8080:80
# Open http://localhost:8080 in your browser
```

### Test API-Middleware
```bash
kubectl port-forward -n api-middleware svc/api-middleware 8081:80
curl http://localhost:8081/get
```

### Test Database
```bash
kubectl port-forward -n backend-database svc/backend-database 5432:5432
psql -h localhost -U postgres -d microservices_db
# password: SecurePassword123!Change
```

---

## 📊 View Service Mesh Status

```bash
# Open Linkerd dashboard
linkerd viz dashboard

# View service topology
linkerd viz edges -A

# Monitor traffic
linkerd viz top -n frontend-ui
linkerd viz stat -n api-middleware
linkerd viz routes -n backend-database
```

---

## ⚠️ Important Production Actions

### 1. Change Database Password
```bash
kubectl edit secret -n backend-database postgres-secret
# Update POSTGRES_PASSWORD with base64-encoded value
```

### 2. Use Specific Image Tags
Update `image:` fields in manifests to use version tags instead of `latest`

### 3. Configure External Access
Add Ingress or LoadBalancer service for external connectivity

### 4. Set Up Monitoring
Install Prometheus and Grafana for metrics collection

### 5. Configure Backups
Schedule PostgreSQL backups for data protection

---

## 📚 Documentation Files

- **DEPLOYMENT_GUIDE.md** - Detailed deployment steps and troubleshooting
- **MICROSERVICES_CONFIG_REFERENCE.md** - Complete configuration reference
- **gitops/apps/README.md** - Architecture overview
- **gitops/apps/[service]/README.md** - Individual service documentation

---

## 🔧 Key Information

### Namespaces
- `frontend-ui` - Web UI service
- `api-middleware` - REST API service
- `backend-database` - PostgreSQL service

### Service DNS Names
- Frontend-UI: `frontend-ui.frontend-ui.svc.cluster.local:80`
- API: `api-middleware.api-middleware.svc.cluster.local:80`
- Database: `backend-database.backend-database.svc.cluster.local:5432`

### Default Database Credentials
- User: `postgres`
- Database: `microservices_db`
- Password: `SecurePassword123!Change` (⚠️ Change in production!)

---

## 🎯 Next Steps

1. ✅ Update repository URL in app.yaml files
2. ✅ Run `./ deploy.sh` script
3. ✅ Wait for all pods to be running
4. ✅ Test connectivity between services
5. ✅ Change database password
6. ✅ Configure external access (Ingress)
7. ✅ Set up monitoring (Prometheus/Grafana)
8. ✅ Schedule backups for database

---

## 💡 Architecture Features

### High Availability
- Multiple replicas per service
- Auto-scaling based on CPU/memory
- Health checks for all endpoints
- Horizontal Pod Autoscaler configured

### Service Mesh Integration
- Linkerd sidecar injection enabled
- Automatic mTLS between services
- Real-time traffic metrics
- Service discovery via DNS

### Infrastructure as Code
- ArgoCD GitOps deployment
- Declarative manifests
- Version controlled configuration

### Production Ready
- Resource limits set
- Security context configured
- Persistent storage for database
- Restart policies configured

---

## 📞 Support

For detailed information on:
- **Deployment**: See `DEPLOYMENT_GUIDE.md`
- **Configuration**: See `MICROSERVICES_CONFIG_REFERENCE.md`
- **Specific Service**: See `gitops/apps/[service]/README.md`
- **Troubleshooting**: See `DEPLOYMENT_GUIDE.md` Troubleshooting section

---

## ✨ What You Can Now Do

🔹 Deploy 3-tier microservices architecture to EKS
🔹 Manage applications through ArgoCD (GitOps)
🔹 Secure inter-service communication with Linkerd mTLS
🔹 Monitor traffic and metrics via Linkerd dashboard
🔹 Auto-scale services based on resource utilization
🔹 Update services by simply pushing to GitOps repository

---

**All files are ready to deploy! Start with Step 1 of the Quick Start above.**
