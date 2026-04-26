#!/usr/bin/env bash  
set -euo pipefail  
  
echo "[setup] Preparing lab..."  
  
# Namespace  
kubectl create namespace echo-sound --dry-run=client -o yaml | kubectl apply -f -  
  
# Reset learner-created objects so task always starts clean  
kubectl -n echo-sound delete svc echo-service --ignore-not-found  
kubectl -n echo-sound delete ingress echo --ignore-not-found  
  
# Ensure expected deployment exists (as per question context)  
cat <<'EOF' | kubectl apply -f -  
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: echoserver-deployment  
  namespace: echo-sound  
  labels:  
    app: echoserver  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: echoserver  
  template:  
    metadata:  
      labels:  
        app: echoserver  
    spec:  
      containers:  
      - name: echoserver  
        image: registry.k8s.io/echoserver:1.10  
        ports:  
        - containerPort: 8080  
EOF  
  
kubectl -n echo-sound rollout status deployment/echoserver-deployment --timeout=180s  
  
# Install ingress-nginx only if missing  
if ! kubectl -n ingress-nginx get deployment ingress-nginx-controller >/dev/null 2>&1; then  
  echo "[setup] Installing ingress-nginx controller..."  
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml  
fi  
  
kubectl -n ingress-nginx wait --for=condition=Available deployment/ingress-nginx-controller --timeout=300s  
  
# Host mapping for example.org  
if ! grep -qE '(^|[[:space:]])example\.org([[:space:]]|$)' /etc/hosts; then  
  echo "127.0.0.1 example.org" >> /etc/hosts  
fi  
  
# Recreate port-forward (needed so curl http://example.org/echo works inside lab VM)  
pkill -f "kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80" || true  
nohup kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80 --address 0.0.0.0 \  
  >/tmp/ingress-pf.log 2>&1 &  
  
sleep 2  
echo "[setup] Lab ready."