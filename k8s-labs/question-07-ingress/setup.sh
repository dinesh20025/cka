#!/usr/bin/env bash  
set -euxo pipefail  
exec > >(tee -a /tmp/setup.log) 2>&1  
  
echo "[setup] started"  
  
# 1) Wait for cluster ready  
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do  
  sleep 3  
done  
  
# 2) Namespace create  
kubectl create namespace echo-sound --dry-run=client -o yaml | kubectl apply -f -  
  
# 3) Clean old learner objects (if any)  
kubectl -n echo-sound delete svc echo-service --ignore-not-found=true || true  
kubectl -n echo-sound delete ingress echo --ignore-not-found=true || true  
  
# 4) Create base deployment (your requested YAML)  
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
  
# 5) Wait a bit for deployment object/pod  
kubectl -n echo-sound rollout status deployment/echoserver-deployment --timeout=180s || true  
  
# 6) Install ingress-nginx if missing  
if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then  
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml  
fi  
  
kubectl -n ingress-nginx wait --for=condition=Available deployment/ingress-nginx-controller --timeout=300s || true  
  
# 7) example.org mapping  
grep -q "example.org" /etc/hosts || echo "127.0.0.1 example.org" >> /etc/hosts  
  
# 8) Port-forward for curl checks  
pkill -f "kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80" || true  
nohup kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80 --address 0.0.0.0 >/tmp/ingress-pf.log 2>&1 &  
  
touch /tmp/lab_setup_done  
echo "[setup] completed"  