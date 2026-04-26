#!/usr/bin/env bash  
set -euo pipefail  
exec > >(tee -a /tmp/setup.log) 2>&1  
  
echo "[setup] started"  
  
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do  
  sleep 3  
done  
  
kubectl create namespace echo-sound --dry-run=client -o yaml | kubectl apply -f -  
  
(  
  echo 'apiVersion: apps/v1'  
  echo 'kind: Deployment'  
  echo 'metadata:'  
  echo '  name: echoserver-deployment'  
  echo '  namespace: echo-sound'  
  echo 'spec:'  
  echo '  replicas: 1'  
  echo '  selector:'  
  echo '    matchLabels:'  
  echo '      app: echo'  
  echo '  template:'  
  echo '    metadata:'  
  echo '      labels:'  
  echo '        app: echo'  
  echo '    spec:'  
  echo '      containers:'  
  echo '      - name: echo'  
  echo '        image: gcr.io/google_containers/echoserver:1.10'  
  echo '        ports:'  
  echo '        - containerPort: 8080'  
) | kubectl apply -f -  
  
kubectl -n echo-sound rollout status deployment/echoserver-deployment --timeout=180s || true  
  
touch /tmp/lab_setup_done  
echo "[setup] completed"