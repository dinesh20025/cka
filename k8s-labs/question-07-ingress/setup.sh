#!/usr/bin/env bash  
set -euo pipefail  
exec > >(tee -a /tmp/setup.log) 2>&1  
  
echo "[setup] started at $(date)"  
  
# Wait for API  
for i in {1..90}; do  
  kubectl get ns >/dev/null 2>&1 && break  
  sleep 2  
done  
  
# Namespace  
kubectl create ns echo-sound --dry-run=client -o yaml | kubectl apply -f -  
  
# Reset learner-created objects  
kubectl -n echo-sound delete svc echo-service --ignore-not-found=true || true  
kubectl -n echo-sound delete ingress echo --ignore-not-found=true || true  
  
# ---- Your requested deployment YAML ----  
cat <<'EOF' | kubectl apply -f -  
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: echoserver-deployment  
  namespace: echo-sound  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: echo  
  template:  
    metadata:  
      labels:  
        app: echo  
    spec:  
      containers:  
      - name: echo  
        image: gcr.io/google_containers/echoserver:1.10  
        ports:  
        - containerPort: 8080  
EOF  
# ----------------------------------------  
  
kubectl -n echo-sound rollout status deploy/echoserver-deployment --timeout=180s || true  
  
# Install ingress-nginx if missing  
if ! kubectl -n ingress-nginx get deploy ingress-nginx-controller >/dev/null 2>&1; then  
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml  
fi  
  
kubectl -n ingress-nginx wait --for=condition=Available deploy/ingress-nginx-controller --timeout=300s || true  
  
# Host mapping  
grep -qE '(^|[[:space:]])example\.org([[:space:]]|$)' /etc/hosts || echo "127.0.0.1 example.org" >> /etc/hosts  
  
# Port-forward for curl checks  
pkill -f "kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80" || true  
nohup kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80 --address 0.0.0.0 \  
  >/tmp/ingress-pf.log 2>&1 &  
  
touch /tmp/lab_setup_done  
echo "[setup] completed at $(date)"