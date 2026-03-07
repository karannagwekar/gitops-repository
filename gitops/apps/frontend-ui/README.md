# Frontend-UI Microservice

Web server microservice for the user interface layer.

## Components

- **Deployment**: 3 replicas of Nginx
- **Service**: ClusterIP on port 80
- **HPA**: Auto-scales between 2-10 pods based on CPU (70%) and memory (80%)
- **Linkerd**: Automatic sidecar injection enabled

## Deployment

This service is deployed via ArgoCD using the `app.yaml` configuration.

## Configuration

### Images & Versions
- Base Image: `nginx:1.24-alpine`
- Platform: x86_64

### Resource Allocation
- **CPU Request**: 100m
- **CPU Limit**: 200m
- **Memory Request**: 64Mi
- **Memory Limit**: 128Mi

### Health Checks
- **Liveness Probe**: HTTP GET / (10s delay, 10s interval)
- **Readiness Probe**: HTTP GET / (5s delay, 5s interval)

## Usage

### Port Forwarding
```bash
kubectl port-forward -n frontend-ui svc/frontend-ui 8080:80
```

Visit `http://localhost:8080` in your browser.

### View Logs
```bash
kubectl logs -n frontend-ui -l app=frontend-ui --tail=50 -f
```

### Scale Manually
```bash
kubectl scale deployment frontend-ui -n frontend-ui --replicas=5
```

## Integration with Service Mesh

This service is configured with Linkerd injection. The namespace automatically injects the Linkerd sidecar into all pods.

To view traffic:
```bash
linkerd viz top -n frontend-ui
linkerd viz stat -n frontend-ui
```

## Customization

### Custom Nginx Configuration
Replace the default image with your custom image:
```yaml
containers:
- name: frontend-ui
  image: your-registry/custom-nginx:latest
```

### Port Changes
Update the containerPort and service targetPort in `manifests.yaml`.

## Troubleshooting

### Pod stuck in pending
```bash
kubectl describe pod -n frontend-ui <pod-name>
```

### Check readiness
```bash
kubectl get pods -n frontend-ui -o wide
```
