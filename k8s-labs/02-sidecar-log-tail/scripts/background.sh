#!/bin/bash

# Wait for node to be Ready (not just API available)
echo "[bg] Waiting for node to be Ready..."
for i in $(seq 1 60); do
  if kubectl get nodes 2>/dev/null | grep -q " Ready"; then
    echo "[bg] Node is Ready."
    break
  fi
  sleep 5
done

# Extra buffer — coredns and other system pods need time
echo "[bg] Waiting for kube-system pods to settle..."
sleep 20

echo "[bg] Creating deployment/wordpress ..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress
  namespace: default
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: wordpress
  strategy:
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: wordpress
    spec:
      terminationGracePeriodSeconds: 30
      containers:
        - name: monitor
          image: lfcert/monitor:latest
          imagePullPolicy: Always
          env:
            - name: LOG_FILENAME
              value: /var/log/wordpress.log
          resources: {}
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
EOF

echo "[bg] Waiting for wordpress deployment to rollout..."
kubectl rollout status deployment/wordpress --timeout=180s || true

echo "[bg] Done."
