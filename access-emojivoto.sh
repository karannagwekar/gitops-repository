#!/bin/bash
# Access Emojivoto through Traefik port-forward
# Usage: ./access-emojivoto.sh

set -e

echo "🚀 Starting Traefik port-forward..."
kubectl port-forward -n traefik svc/traefik 8000:80 2>/dev/null &
PF_PID=$!

trap "kill $PF_PID 2>/dev/null; echo 'Port-forward stopped'" EXIT

echo "✅ Traefik is now accessible at http://localhost:8000"
echo "🌐 Emojivoto available at:"
echo "   - http://emojivoto.local:8000"
echo "   - http://emojivoto.localhost:8000"
echo ""
echo "Press Ctrl+C to stop the port-forward..."

wait $PF_PID
