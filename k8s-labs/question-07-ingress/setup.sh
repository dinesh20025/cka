#!/bin/bash  
set -euo pipefail  
  
# 1) Namespace + deployment (student will create service/ingress)  
kubectl create ns echo-sound --dry-run=client -o yaml | kubectl apply -f -  
  
cat <<EOF | kubectl apply -f -  
apiVersion: apps/v1  
kind: Deployment  
metadata:  
  name: echo-deployment  
  namespace: echo-sound  
  labels:  
    app: echo-app  
spec:  
  replicas: 1  
  selector:  
    matchLabels:  
      app: echo-app  
  template:  
    metadata:  
      labels:  
        app: echo-app  
    spec:  
      containers:  
      - name: echo  
        image: hashicorp/http-echo:1.0.0  
        args:  
        - "-text=echo-ok"  
        - "-listen=:8080"  
        ports:  
        - containerPort: 8080  
EOF  
  
# 2) Install ingress-nginx (if not already installed)  
if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then  
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/cloud/deploy.yaml  
fi  
  
kubectl -n ingress-nginx wait --for=condition=ready pod \  
  -l app.kubernetes.io/component=controller --timeout=300s  
  
# 3) example.org -> localhost mapping  
if ! grep -q "example.org" /etc/hosts; then  
  echo "127.0.0.1 example.org" >> /etc/hosts  
fi  
  
# 4) Port-forward ingress controller to local 80 (for curl http://example.org/echo)  
pkill -f "kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80" || true  
nohup kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80 --address 0.0.0.0 \  
  >/tmp/ingress-pf.log 2>&1 &  
  
echo "Setup complete"  