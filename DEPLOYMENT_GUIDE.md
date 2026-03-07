# Microservices Deployment Guide

## Prerequisites Checklist

Before deploying, ensure you have:

- [ ] EKS cluster (v1.25 or higher) up and running
- [ ] `kubectl` configured to access your EKS cluster
- [ ] ArgoCD v2.x installed on the cluster
- [ ] Linkerd 2.13+ installed on the cluster
- [ ] This GitOps repository cloned and accessible
- [ ] GitHub account with read access to this repository (if private)

## Verification Commands

### 1. Verify Cluster Access
```bash
kubectl cluster-info
kubectl get nodes
```

### 2. Verify ArgoCD Installation
```bash
kubectl get all -n argocd
argocd version
```

### 3. Verify Linkerd Installation
```bash
linkerd version
linkerd check
kubectl get ns linkerd
```

## Deployment Steps

### Option A: Using Deployment Script (Recommended)

1. Make script executable:
   ```bash
   chmod +x deploy.sh
   ```

2. Run deployment script:
   ```bash
   ./deploy.sh https://github.com/your-org/gitops-repository
   ```

3. Monitor deployment:
   ```bash
   kubectl get applications -n argocd -w
   ```

### Option B: Manual Deployment

1. **Update Repository URL**
   
   Edit each application file and replace `https://github.com/your-org/gitops-repository` with your actual repository URL:
   
   ```bash
   sed -i.bak 's|https://github.com/your-org/gitops-repository|YOUR_REPO_URL|g' gitops/apps/*/app.yaml
   ```

2. **Apply ArgoCD Applications**
   
   ```bash
   kubectl apply -f gitops/apps/frontend-ui/app.yaml
   kubectl apply -f gitops/apps/api-middleware/app.yaml
   kubectl apply -f gitops/apps/backend-database/app.yaml
   ```

3. **Verify Deployment**
   
   ```bash
   kubectl get applications -n argocd
   argocd app list
   ```

## Monitoring Deployment Progress

### Check ArgoCD Sync Status
```bash
# List all applications
argocd app list

# Get detailed status of an application
argocd app get frontend-ui
argocd app get api-middleware
argocd app get backend-database

# Watch real-time sync
kubectl get applications -n argocd -w
```

### Check Pod Status
```bash
# Watch frontend-ui pods
kubectl get pods -n frontend-ui -w

# Watch API middleware pods
kubectl get pods -n api-middleware -w

# Watch database pod
kubectl get pods -n backend-database -w

# View all pods in all namespaces
kubectl get pods -A | grep -E "frontend-ui|api-middleware|backend-database"
```

### Check for Errors
```bash
# View pod events
kubectl describe pods -n frontend-ui
kubectl describe pods -n api-middleware
kubectl describe pods -n backend-database

# Check pod logs
kubectl logs -n frontend-ui -l app=frontend-ui
kubectl logs -n api-middleware -l app=api-middleware
kubectl logs -n backend-database -l app=backend-database
```

## Verifying Linkerd Injection

### Check Namespace Labels
```bash
# All namespaces should have linkerd.io/inject=enabled
kubectl get namespaces -L linkerd.io/inject
```

### Check Sidecar Injection
```bash
# All pods should have 2 containers (app + linkerd-proxy)
kubectl get pods -n frontend-ui -o jsonpath='{.items[*].spec.containers[*].name}'
kubectl get pods -n api-middleware -o jsonpath='{.items[*].spec.containers[*].name}'
kubectl get pods -n backend-database -o jsonpath='{.items[*].spec.containers[*].name}'
```

### View Service Mesh Metrics
```bash
# Dashboard view of mesh
linkerd viz dashboard

# View all service endpoints
linkerd viz edges -A

# View traffic to/from services
linkerd viz top -n frontend-ui
linkerd viz stat -n api-middleware
linkerd viz routes -n backend-database

# View live traffic
linkerd viz live -n frontend-ui
```

## Testing Connectivity

### Test Frontend-UI
```bash
# Port forward
kubectl port-forward -n frontend-ui svc/frontend-ui 8080:80 &

# Test with curl
curl http://localhost:8080

# Open in browser
open http://localhost:8080

# Kill port forward
kill %1
```

### Test API-Middleware
```bash
# Port forward
kubectl port-forward -n api-middleware svc/api-middleware 8081:80 &

# Test endpoints
curl http://localhost:8081/get
curl http://localhost:8081/ip
curl -X POST http://localhost:8081/post -d "data=test"

# Kill port forward
kill %1
```

### Test Database
```bash
# Port forward
kubectl port-forward -n backend-database svc/backend-database 5432:5432 &

# Install PostgreSQL client if needed
# macOS: brew install postgresql

# Connect to database
psql -h localhost -U postgres -d microservices_db

# At the psql prompt:
# - List databases: \l
# - List tables: \dt
# - Create table: CREATE TABLE test (id SERIAL, name VARCHAR(100));
# - Exit: \q

# Kill port forward
kill %1
```

### Test Inter-Service Communication
```bash
# From frontend pod, call API middleware
kubectl exec -it -n frontend-ui <frontend-pod-name> -- curl http://api-middleware.api-middleware.svc.cluster.local/get

# From API middleware pod, call database
kubectl exec -it -n api-middleware <api-pod-name> -- curl postgres://backend-database.backend-database.svc.cluster.local:5432
```

## Customization

### Change Database Password (Important for Production!)

1. Edit the secret:
   ```bash
   kubectl edit secret -n backend-database postgres-secret
   ```

2. Update the POSTGRES_PASSWORD field with base64-encoded value:
   ```bash
   # Generate base64-encoded password
   echo -n "YourNewSecurePassword" | base64
   ```

3. Replace the old value in the secret

4. Restart the pod to apply changes:
   ```bash
   kubectl delete pod -n backend-database backend-database-0
   ```

### Scale Applications

```bash
# Manual scaling
kubectl scale deployment -n frontend-ui frontend-ui --replicas=5
kubectl scale deployment -n api-middleware api-middleware --replicas=5

# Check HPA status
kubectl get hpa -n frontend-ui
kubectl get hpa -n api-middleware
kubectl get hpa -n backend-database

# View HPA events
kubectl describe hpa -n frontend-ui frontend-ui
```

### Update Container Images

Edit the respective `manifests.yaml` file and update the `image` field, then apply:

```bash
kubectl apply -f gitops/apps/frontend-ui/manifests.yaml
kubectl apply -f gitops/apps/api-middleware/manifests.yaml
kubectl apply -f gitops/apps/backend-database/manifests.yaml

# Or let ArgoCD handle updates by pushing to the repository
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n frontend-ui -o wide

# Describe the problematic pod
kubectl describe pod -n frontend-ui <pod-name>

# Check resource requests vs available resources
kubectl top nodes
kubectl describe nodes
```

### Service Mesh Issues

```bash
# Verify Linkerd health
linkerd check

# Check sidecar logs
kubectl logs -n frontend-ui <pod-name> linkerd-proxy

# Check if probe injection is interfering
kubectl get pod -n frontend-ui -o yaml | grep -A5 "probes"
```

### Database Connection Issues

```bash
# Check if database pod is ready
kubectl get pods -n backend-database -o wide

# Test database from pod
kubectl exec -it -n backend-database backend-database-0 -- psql -U postgres -d microservices_db -c "SELECT 1;"

# Check logs for errors
kubectl logs -n backend-database backend-database-0
```

### ArgoCD Sync Issues

```bash
# Check application status
argocd app get frontend-ui --refresh

# Force re-sync
argocd app sync frontend-ui

# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

## Production Considerations

### Security
- [ ] Change default database password
- [ ] Use AWS Secrets Manager or HashiCorp Vault for credentials
- [ ] Implement NetworkPolicies for service mesh traffic
- [ ] Enable RBAC for Kubernetes access
- [ ] Use private image registries

### High Availability
- [ ] Use multiple replicas for all services
- [ ] Configure PodDisruptionBudgets
- [ ] Set up multi-region failover
- [ ] Enable backup and restore procedures

### Performance
- [ ] Right-size resource requests/limits
- [ ] Monitor and optimize database queries
- [ ] Implement caching strategies
- [ ] Configure load balancing policies in Linkerd

### Monitoring & Logging
- [ ] Set up Prometheus for metrics
- [ ] Configure Grafana dashboards
- [ ] Enable centralized logging with ELK or similar
- [ ] Set up alerts for critical metrics

### Backup & Recovery
- [ ] Schedule regular PostgreSQL backups
- [ ] Test backup restoration procedures
- [ ] Document disaster recovery processes
- [ ] Store backups in multiple locations

## Cleanup

To remove all deployed applications:

```bash
# Delete ArgoCD applications
kubectl delete -f gitops/apps/frontend-ui/app.yaml
kubectl delete -f gitops/apps/api-middleware/app.yaml
kubectl delete -f gitops/apps/backend-database/app.yaml

# This will also delete the associated resources in each namespace
```

## Support & Documentation

For more information:
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Linkerd Documentation](https://linkerd.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [EKS Best Practices](https://aws.amazon.com/eks/best-practices/)
