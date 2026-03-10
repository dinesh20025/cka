# ArgoCD Installation Lab

In this lab you will install **ArgoCD** in a Kubernetes cluster and access its UI.

---

## Task 1

Create a namespace called:

```
argocd
```

---

## Task 2

Install ArgoCD using the official installation manifest.

Use the following manifest:

```
https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

---

## Task 3

Verify that all pods in the `argocd` namespace are running.

Command example:

```
kubectl get pods -n argocd
```

All pods should reach **Running** state.

---

## Task 4

Expose the ArgoCD API server locally using port-forward.

Forward port:

```
8080
```

to the ArgoCD server service.

---

## Task 5

Retrieve the initial admin password from the secret:

```
argocd-initial-admin-secret
```

Decode it using base64.

---

## Task 6

Use the credentials to login to ArgoCD UI.

Username:

```
admin
```

Password:

```
<decoded password>
```

---

## Verification

Confirm ArgoCD server is running:

```
kubectl get svc -n argocd
```

You should see:

```
argocd-server
```

---
