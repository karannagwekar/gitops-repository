# API-Middleware Microservice

REST API and middleware service for business logic processing.

## Components

- **Deployment**: 3 replicas of httpbin API service
- **Service**: ClusterIP on port 80
- **HPA**: Auto-scales between 2-10 pods based on CPU (75%) and memory (80%)
- **Linkerd**: Automatic sidecar injection enabled

## Deployment

This service is deployed via ArgoCD using the `app.yaml` configuration.

## Configuration

### Images & Versions
- Base Image: `kennethreitz/httpbin:latest`
- Platform: x86_64

### Resource Allocation
- **CPU Request**: 200m
- **CPU Limit**: 500m
- **Memory Request**: 128Mi
- **Memory Limit**: 256Mi

### Environment Variables
- `PORT`: 80 (HTTP port)

### Health Checks
- **Liveness Probe**: HTTP GET /get (15s delay, 10s interval)
- **Readiness Probe**: HTTP GET /get (10s delay, 5s interval)

### Security Context
- Non-root user (uid: 1000)

## Usage

### Port Forwarding
```bash
kubectl port-forward -n api-middleware svc/api-middleware 8081:80
```

Test the API:
```bash
curl http://localhost:8081/get
curl -X POST http://localhost:8081/post -d "key=value"
```

### View Logs
```bash
kubectl logs -n api-middleware -l app=api-middleware --tail=50 -f
```

### Scale Manually
```bash
kubectl scale deployment api-middleware -n api-middleware --replicas=5
```

## Available Endpoints

httpbin provides various testing endpoints:

- `GET /get` - Returns GET request data
- `POST /post` - Returns POST request data
- `PUT /put` - Returns PUT request data
- `DELETE /delete` - Returns DELETE request data
- `PATCH /patch` - Returns PATCH request data
- `GET /headers` - Returns request headers
- `GET /ip` - Returns client IP
- `GET /user-agent` - Returns user agent
- `GET /status/<code>` - Returns specified HTTP status code
- `GET /delay/<seconds>` - Delays response by N seconds

## Integration with Service Mesh

This service is configured with Linkerd injection. The namespace automatically injects the Linkerd sidecar into all pods.

To view traffic:
```bash
linkerd viz top -n api-middleware
linkerd viz stat -n api-middleware
linkerd viz routes -n api-middleware
```

## Customization

### Custom API Image
Replace httpbin with your custom API service:
```yaml
containers:
- name: api-middleware
  image: your-registry/custom-api:v1.0.0
```

### Port Changes
Update the containerPort and service targetPort in `manifests.yaml`.

### Environment Variables
Add additional environment variables in the `env` section of `manifests.yaml`.

## Connecting to Backend Database

To connect this microservice to the backend PostgreSQL database:

```bash
# Get database service DNS
backend-database.backend-database.svc.cluster.local:5432

# Connection string
DATABASE_URL=postgresql://postgres:PASSWORD@backend-database.backend-database.svc.cluster.local:5432/microservices_db
```

## Troubleshooting

### Pod stuck in pending
```bash
kubectl describe pod -n api-middleware <pod-name>
```

### Check API response
```bash
kubectl exec -it -n api-middleware <pod-name> -- curl localhost/get
```

### Check readiness
```bash
kubectl get pods -n api-middleware -o wide
```
