#!/bin/bash

echo "[bg] Waiting for node to be Ready..."
for i in $(seq 1 60); do
  if kubectl get nodes 2>/dev/null | grep -q " Ready"; then
    echo "[bg] Node is Ready."
    break
  fi
  sleep 5
done

echo "[bg] Waiting for kube-system pods to settle..."
sleep 20

echo "[bg] Creating deployment/webapp ..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  namespace: default
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
          volumeMounts:
            - name: log-volume
              mountPath: /var/log
      volumes:
        - name: log-volume
          emptyDir: {}
EOF

echo "[bg] Waiting for webapp rollout..."
kubectl rollout status deployment/webapp --timeout=180s || true

echo "[bg] Done. deployment/webapp is ready."
