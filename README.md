# GitOps Repository

A GitOps repository containing application codebases, Helm charts, and EKS deployment configurations. This repository is deployed to Kubernetes clusters (k3d and EKS) via ArgoCD, which is provisioned through a separate Terraform repository.

## Overview

This repository follows the GitOps methodology where:
- **Git is the source of truth** - All desired state configurations are stored here
- **ArgoCD is the deployment engine** - ArgoCD monitors this repository and automatically syncs changes to the cluster
- **Infrastructure as Code** - All deployments are version-controlled and auditable

## Repository Structure

```
.
├── apps/                    # Application source code
│   └── [app-name]/         # Individual application directories
├── helm-charts/            # Helm charts for applications
│   └── [chart-name]/       # Individual Helm chart directories
├── eks-deployment/         # EKS-specific deployment configurations
│   ├── cluster-config/     # Cluster-level configurations
│   ├── namespaces/         # Namespace definitions
│   └── argocd-apps/        # ArgoCD Application manifests
└── README.md
```

## Prerequisites

- **ArgoCD**: Already deployed in your cluster via Terraform (separate repository)
- **kubectl**: Configured to access your k3d or EKS cluster
- **Helm 3**: For managing Helm charts locally (optional, ArgoCD can handle this)
- **Git**: For version control and triggering deployments

## Deployment Workflow

1. **Commit Changes**: Push application code, Helm charts, or deployment configs to this repository
2. **ArgoCD Detection**: ArgoCD automatically detects changes in this repository
3. **Sync**: ArgoCD syncs the desired state to the Kubernetes cluster
4. **Verify**: Monitor deployments in ArgoCD UI or via kubectl

## Adding a New Application

1. Create application source code in `apps/[app-name]/`
2. Create a Helm chart in `helm-charts/[chart-name]/`
3. Create an ArgoCD Application manifest in `eks-deployment/argocd-apps/[app-name].yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: [app-name]
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/[your-org]/gitops-repository
    targetRevision: HEAD
    path: helm-charts/[chart-name]
  destination:
    server: https://kubernetes.default.svc
    namespace: [app-namespace]
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

4. Commit and push to trigger ArgoCD sync

## Cluster Targets

- **k3d**: Lightweight Kubernetes for local development and testing
- **EKS**: AWS Elastic Kubernetes Service for production

## ArgoCD Configuration

ArgoCD is provisioned via Terraform in a separate repository and configured to:
- Watch this repository for changes
- Automatically sync applications to the cluster
- Support multiple environments/clusters

## Useful Commands

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View application details
argocd app get [app-name]

# Manually sync an application
argocd app sync [app-name]

# Forward to ArgoCD UI (if needed)
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

## Best Practices

- **Semantic Versioning**: Tag releases in this repository
- **Branch Protection**: Use branch protection rules for the main branch
- **PR Reviews**: Require reviews before merging to ensure configuration quality
- **Namespace Isolation**: Use separate namespaces for different applications/environments
- **Resource Limits**: Define resource requests and limits in Helm charts
- **Monitoring**: Use ArgoCD notifications to alert on sync failures

## Related Documentation

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## License

[Add your license here]