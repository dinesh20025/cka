#!/usr/bin/env bash  
set -euo pipefail  
  
# Wait until Kubernetes API is ready  
wait_kube() {  
  echo "Waiting for Kubernetes API..."  
  for i in $(seq 1 60); do  
    if kubectl get ns >/dev/null 2>&1; then  
      return 0  
    fi  
    sleep 2  
  done  
  echo "Kubernetes API not ready"  
  exit 1  
}  
  
wait_kube  
  
# Seed lab: existing deployment "wordpress" (single container, no sidecar yet)  
cat <<'EOF' | kubectl apply -f -  
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: wordpress  
  labels:  
    app: wordpress  
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
              i=0  
              while true; do  
                echo "$(date -Iseconds) wordpress log line ${i}" >> /var/log/wordpress.log  
                i=$((i+1))  
                sleep 2  
              done  
EOF  
  
kubectl rollout status deployment/wordpress --timeout=120s  
echo "Background setup complete: deployment/wordpress is ready."
