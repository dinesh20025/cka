#!/usr/bin/env bash  
set -euo pipefail  
  
# Wait for cluster  
until kubectl get nodes >/dev/null 2>&1; do  
  sleep 2  
done  
  
# Create initial deployment (without sidecar)  
cat <<'EOF' | kubectl apply -f -  
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: wordpress  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: wordpress  
  template:  
    metadata:  
      labels:  
        app: wordpress  
    spec:  
      containers:  
      - name: wordpress  
        image: busybox:stable  
        command: ["/bin/sh", "-c"]  
        args:  
        - |  
          mkdir -p /var/log  
          touch /var/log/wordpress.log  
          while true; do  
            echo "$(date) wordpress log line" >> /var/log/wordpress.log  
            sleep 2  
          done  
EOF  
  
kubectl wait --for=condition=available --timeout=120s deployment/wordpress  
echo "Lab setup complete: deployment/wordpress is ready."
