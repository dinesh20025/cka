#!/bin/bash
until kubectl get nodes 2>/dev/null | grep -q " Ready"; do sleep 3; done
kubectl create deployment webapp --image=busybox:1.36 -- /bin/sh -c 'mkdir -p /var/log; while true; do echo "$(date) log entry" >> /var/log/application.log; sleep 2; done'
