# Accessing Emojivoto

Emojivoto is deployed and running in the cluster with Traefik ingress routing configured.

## Quick Start

### Option 1: Using Port-Forward (Recommended for k3d)

```bash
./access-emojivoto.sh
```

Then access at:
- http://emojivoto.local:8000
- http://emojivoto.localhost:8000
- http://localhost:8000 (direct)

### Option 2: Direct LoadBalancer Access

The Traefik LoadBalancer is exposed at `172.18.0.201` within the k3d cluster network. This IP is not directly accessible from the host machine on k3d due to network isolation.

## Architecture

- **Emojivoto**: Three microservices (web, emoji, voting) running in the `emojivoto` namespace
- **Traefik**: Ingress controller with IngressRoute CRD support at `172.18.0.201` (LoadBalancer)
- **MetalLB**: Load balancer providing the external IP within the cluster network
- **ArgoCD**: GitOps controller managing all deployments

## Service Details

- **Web Service**: http://emojivoto-web-svc:80 (IngressRoute routes external requests here)
- **Emoji Service**: http://emoji-svc:8801 (internal gRPC, called by web)
- **Voting Service**: http://voting-svc:8801 (internal gRPC, called by web)

## DNS Configuration

Add to `/etc/hosts`:
```
127.0.0.1  emojivoto.local
127.0.0.1  emojivoto.localhost
```

## Traefik Dashboard

To access the Traefik dashboard:

```bash
kubectl port-forward -n traefik svc/traefik 8080:8080
```

Then visit: http://localhost:8080/dashboard/

## Logs

View application logs:

```bash
# Web service
kubectl logs -n emojivoto deployment/web

# Emoji service
kubectl logs -n emojivoto deployment/emoji

# Voting service
kubectl logs -n emojivoto deployment/voting

# Traefik
kubectl logs -n traefik deployment/traefik

# MetalLB Controller
kubectl logs -n metallb-system deployment/controller

# MetalLB Speaker
kubectl logs -n metallb-system -l app=metallb,component=speaker
```

## Deployment Status

Check deployment status:

```bash
kubectl get all -n emojivoto
kubectl get all -n traefik
kubectl get all -n metallb-system
kubectl get applications -n argocd
```
