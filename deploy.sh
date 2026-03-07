#!/bin/bash

# Quick deployment script for microservices on EKS with ArgoCD and Linkerd
# Usage: ./deploy.sh <REPO_URL>

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <REPO_URL>"
    echo "Example: $0 https://github.com/my-org/gitops-repository"
    exit 1
fi

REPO_URL="$1"

echo "=========================================="
echo "Microservices Deployment Script"
echo "=========================================="
echo ""
echo "Repository URL: $REPO_URL"
echo ""

# Update app.yaml files with repository URL
echo "[1/5] Updating ArgoCD Application configurations..."
for app_dir in frontend-ui api-middleware backend-database; do
    if [ -f "gitops/apps/$app_dir/app.yaml" ]; then
        sed -i.bak "s|https://github.com/your-org/gitops-repository|${REPO_URL}|g" "gitops/apps/$app_dir/app.yaml"
        echo "  ✓ Updated gitops/apps/$app_dir/app.yaml"
    fi
done

# Verify ArgoCD is installed
echo ""
echo "[2/5] Checking ArgoCD installation..."
if kubectl get ns argocd > /dev/null 2>&1; then
    echo "  ✓ ArgoCD namespace found"
else
    echo "  ⚠ ArgoCD not found. Please install ArgoCD first:"
    echo "    kubectl create namespace argocd"
    echo "    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    exit 1
fi

# Verify Linkerd is installed
echo ""
echo "[3/5] Checking Linkerd installation..."
if kubectl get ns linkerd > /dev/null 2>&1; then
    echo "  ✓ Linkerd namespace found"
else
    echo "  ⚠ Linkerd not found. Please install Linkerd first:"
    echo "    curl --proto '=https' --tlsv1.2 -sSLO https://github.com/linkerd/linkerd2/releases/download/stable-2.14.4/linkerd2-cli-stable-2.14.4-darwin-amd64"
    echo "    sudo install -c -m 0755 linkerd2-cli-stable-2.14.4-darwin-amd64 /usr/local/bin/linkerd"
    echo "    linkerd install | kubectl apply -f -"
    exit 1
fi

# Deploy applications
echo ""
echo "[4/5] Deploying applications to ArgoCD..."

for app_dir in frontend-ui api-middleware backend-database; do
    app_name=$(basename "$app_dir")
    if kubectl apply -f "gitops/apps/$app_dir/app.yaml" 2>/dev/null; then
        echo "  ✓ Deployed $app_name"
    else
        echo "  ✗ Failed to deploy $app_name"
    fi
done

# Wait for ArgoCD sync
echo ""
echo "[5/5] Waiting for ArgoCD synchronization..."
sleep 5

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Monitor deployment status:"
echo "   kubectl get applications -n argocd"
echo "   argocd app list"
echo ""
echo "2. Check pod status:"
echo "   kubectl get pods -n frontend-ui"
echo "   kubectl get pods -n api-middleware"
echo "   kubectl get pods -n backend-database"
echo ""
echo "3. Verify Linkerd injection:"
echo "   linkerd check"
echo "   linkerd viz stat namespaces"
echo ""
echo "4. Port forward to access services:"
echo "   kubectl port-forward -n frontend-ui svc/frontend-ui 8080:80"
echo "   kubectl port-forward -n api-middleware svc/api-middleware 8081:80"
echo "   kubectl port-forward -n backend-database svc/backend-database 5432:5432"
echo ""
echo "5. View service mesh topology:"
echo "   linkerd viz dashboard"
echo ""
