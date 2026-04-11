#!/usr/bin/env bash
set -euo pipefail

echo "Preparing lab environment..."

# Create directory required for the exercise
mkdir -p /home/argo

kubectl create ns argocd

echo "Environment ready"
