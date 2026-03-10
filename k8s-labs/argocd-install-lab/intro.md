# ArgoCD Helm Installation Lab

## Scenario

Install **Argo CD** in a Kubernetes cluster using **Helm** while ensuring that **CRDs are NOT installed**, as they are already pre-installed in the cluster.

---

## Requirements

1. Add the official Argo CD Helm repository with the name **argocd**.
2. Generate a Helm template from the Argo CD chart **version 7.7.3**.
3. Ensure **CRDs are not installed** by configuring the chart appropriately.
4. Save the generated YAML manifest to:
