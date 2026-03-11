#!/usr/bin/env bash
set -euo pipefail

FILE="/home/argo/argo-helm.yaml"

if [ -f "$FILE" ]; then
  echo "✔ Manifest generated"
  exit 0
else
  echo "✘ File not found: $FILE"
  exit 1
fi
