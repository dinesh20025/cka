# ArgoCD Helm Template Lab

## Scenario

Install **Argo CD** in a Kubernetes cluster using **Helm** while ensuring that **CRDs are NOT installed**, as they are already pre-installed in the cluster.

---

## Requirements

1. Add the official **Argo CD Helm repository** with the name **argocd**.

2. Verify that the repository has been added successfully.

3. Generate a Helm template from the **Argo CD chart version 7.7.3**.

4. Ensure that **CRDs are NOT installed** by configuring the chart accordingly.

5. Save the generated YAML manifest to the following location:

/home/argo/argo-helm.yaml


6. Verify that the file was generated successfully.

---

## Helpful Commands

You may find the following commands useful while solving this task.

helm repo add argocd https://argoproj.github.io/argo-helm

helm repo update

helm template argocd argocd/argo-cd --version 7.7.3 --namespace argocd --set crds.install=false > /home/candidate/argocd-manifest.yaml

Check Helm repositories:

helm repo list

You will also need to:

- specify the **chart version**
- configure the chart so that **credentials/CRDs are not installed**
- redirect the output to a file

---

## Expected Outcome

A file should exist at:
/home/argo/argo-helm.yaml


The file should contain Kubernetes manifests generated from the **ArgoCD Helm chart**.
