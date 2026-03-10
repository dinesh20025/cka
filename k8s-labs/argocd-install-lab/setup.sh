#!/bin/bash

echo "Preparing Kubernetes cluster..."

kubectl get nodes

echo "Cluster ready for ArgoCD installation"

mkdir -p /home/argo
