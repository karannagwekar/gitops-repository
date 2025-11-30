# GitOps Repo for k3d Cluster (Traefik + MetalLB)

This repository contains ArgoCD-managed applications for:

- Traefik v2.11.2 (Ingress Controller)
- MetalLB (LoadBalancer for bare-metal/k3d)

Structure:

apps/      → ArgoCD Applications (App-of-Apps)
manifests/ → Additional manifests (MetalLB pool + L2Adv)

Sync the root application `apps/apps.yaml` in ArgoCD.
