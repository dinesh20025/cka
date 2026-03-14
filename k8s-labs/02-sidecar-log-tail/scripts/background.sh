#!/usr/bin/env bash  
set -euo pipefail  
  
echo "[bg] Waiting for Kubernetes API..."  
for i in $(seq 1 90); do  
  if kubectl get ns >/dev/null 2>&1; then  
    break  
  fi  
  sleep 2  
done  
  
echo "[bg] Creating deployment/webapp ..."  
cat <<'EOF' | kubectl apply -f -  
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: webapp  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: webapp  
  template:  
    metadata:  
      labels:  
        app: webapp  
    spec:  
      containers:  
      - name: webapp  
        image: busybox:1.36  
        command: ["/bin/sh", "-c"]  
        args:  
        - |  
          mkdir -p /var/log  
          i=0  
          while true; do  
            echo "$(date -Iseconds) app-line-$i" >> /var/log/application.log  
            i=$((i+1))  
            sleep 2  
          done  
EOF  
  
kubectl rollout status deployment/webapp --timeout=120s  
echo "[bg] Done. deployment/webapp is ready."  
