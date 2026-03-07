# Backend-Database Microservice

PostgreSQL database backend service for persistent data storage.

## Components

- **StatefulSet**: PostgreSQL instance with persistent storage
- **Service**: ClusterIP on port 5432 (Headless for StatefulSet)
- **PersistentVolumeClaim**: 20Gi EBS volume (gp2)
- **HPA**: Auto-scales between 1-3 pods based on CPU (80%)
- **Linkerd**: Automatic sidecar injection enabled
- **ConfigMap**: Database configuration
- **Secret**: Database credentials

## Deployment

This service is deployed via ArgoCD using the `app.yaml` configuration.

## Configuration

### Images & Versions
- Base Image: `postgres:15-alpine`
- Platform: x86_64

### Resource Allocation
- **CPU Request**: 250m
- **CPU Limit**: 1000m
- **Memory Request**: 256Mi
- **Memory Limit**: 512Mi

### Storage
- **Size**: 20Gi
- **StorageClass**: gp2 (AWS EBS)
- **Mount Path**: /var/lib/postgresql/data

### Default Credentials
- **Database User**: postgres
- **Database Name**: microservices_db
- **Default Password**: SecurePassword123!Change ⚠️ **CHANGE THIS IN PRODUCTION**

### Health Checks
- **Liveness Probe**: `pg_isready -U postgres` (30s delay, 10s interval)
- **Readiness Probe**: `pg_isready -U postgres` (15s delay, 5s interval)

### Security Context
- PostgreSQL user (uid: 999)
- fsGroup: 999

## Usage

### Connect to Database

#### Port Forwarding
```bash
kubectl port-forward -n backend-database svc/backend-database 5432:5432 &
psql -h localhost -U postgres -d microservices_db
```

#### From Inside Cluster
```bash
# Get the correct DNS name for StatefulSet
backend-database-0.backend-database.backend-database.svc.cluster.local

# Connection string
postgresql://postgres:PASSWORD@backend-database-0.backend-database.backend-database.svc.cluster.local:5432/microservices_db
```

### View Logs
```bash
kubectl logs -n backend-database -l app=backend-database --tail=100 -f
```

### Execute Commands in Pod
```bash
kubectl exec -it -n backend-database backend-database-0 -- psql -U postgres
```

### PostgreSQL Operations
```bash
# List databases
kubectl exec -it -n backend-database backend-database-0 -- psql -U postgres -l

# Create a table
kubectl exec -it -n backend-database backend-database-0 -- psql -U postgres -d microservices_db -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name VARCHAR(100));"

# Query data
kubectl exec -it -n backend-database backend-database-0 -- psql -U postgres -d microservices_db -c "SELECT * FROM users;"

# Backup database
kubectl exec -it -n backend-database backend-database-0 -- pg_dump -U postgres microservices_db > backup.sql
```

## Integration with Service Mesh

This service is configured with Linkerd injection. The namespace automatically injects the Linkerd sidecar into all pods.

To view traffic:
```bash
linkerd viz top -n backend-database
linkerd viz stat -n backend-database
```

## Security

### Production Recommendations

1. **Change Default Password**
   ```bash
   kubectl patch secret -n backend-database postgres-secret -p '{"data":{"POSTGRES_PASSWORD":"'$(echo -n YourSecurePassword | base64)'"}}'
   ```

2. **Use External Secrets Manager**
   - Consider using AWS Secrets Manager or HashiCorp Vault
   - Update Secret reference in manifests

3. **Network Policies**
   - Restrict access to database from specific namespaces

4. **Backup Strategy**
   - Regular scheduled backups
   - Consider WAL archiving for point-in-time recovery

5. **Monitoring**
   - Enable PostgreSQL logging
   - Set up monitoring for replication lag and storage usage

## Scaling

Currently limited to 1 replica (StatefulSets with persistent storage require careful scaling). To enable read replicas:

1. Create additional StatefulSet with replication configuration
2. Or use PostgreSQL Operator for managed HA setup

## Persistence

### Storage Configuration

The PersistentVolumeClaim uses AWS EBS (gp2). To change:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  storageClassName: your-storage-class  # Change this
  resources:
    requests:
      storage: 20Gi  # Adjust size
```

### Backup

Create periodic backups:
```bash
# Manual backup
kubectl exec -n backend-database backend-database-0 -- pg_dump -U postgres microservices_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
kubectl cp backup.sql backend-database/backend-database-0:/tmp/
kubectl exec -n backend-database backend-database-0 -- psql -U postgres microservices_db < /tmp/backup.sql
```

## Troubleshooting

### Pod stuck in pending
```bash
kubectl describe pvc -n backend-database postgres-pvc
kubectl describe pod -n backend-database backend-database-0
```

### Cannot connect to database
```bash
# Check if pod is running
kubectl get pods -n backend-database

# Check logs
kubectl logs -n backend-database backend-database-0

# Verify PVC is bound
kubectl get pvc -n backend-database
```

### Database corruption
```bash
# Check PostgreSQL logs
kubectl logs -n backend-database backend-database-0 | grep ERROR

# Restart pod (WARNING: may lose in-flight transactions)
kubectl delete pod -n backend-database backend-database-0
```

### Storage full
```bash
# Check storage usage
kubectl exec -it -n backend-database backend-database-0 -- du -sh /var/lib/postgresql/data

# Resize PVC (only after verifying storage class supports expansion)
kubectl patch pvc postgres-pvc -n backend-database -p '{"spec":{"resources":{"requests":{"storage":"50Gi"}}}}'
```
