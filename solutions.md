# ArgoCD Helm + CRDs (1-Page Cheat Sheet)

---

## 🎯 Scenario Types 

### ✅ Case 1: "CRDs already installed"
✔ use: `--set crds.install=false`  
✔ DO NOT delete CRDs  

---

### ✅ Case 2: "Normal install"
✔ no flag needed  
✔ Helm CRDs khud install karega  

---

### ❌ Case 3: "Generate YAML only"
✔ use: `helm template`  
✔ NO `helm install`  
✔ skip CRDs  

---

## ⚡ Core Commands

### 🔹 Add repo
```bash
helm repo add argocd https://argoproj.github.io/argo-helm
helm repo update

helm template argocd argocd/argo-cd --version 9.1.4 --namespace argocd  --set crds.install=false > /root/argo-helm.yaml

grep -c "CustomResourceDefinition" /root/argo-helm.yaml
# 0 = ✅ correct

helm install argocd argocd/argo-cd  --version 9.1.4  -n argocd   --set crds.install=false
```

---

🎯 Your Tasks:
Task 1: Scale Down the Deployment
Scale down the python-webapp deployment in the python-ml-ns namespace to 0 replicas to safely make configuration changes.

Task 2: Calculate Resource Allocation
Important: Before editing the deployment, you need to calculate the correct resource values.

Requirements:

The deployment will run 3 pods
Resources must be divided evenly across all 3 pods
Add 20% overhead to avoid node instability (reserve 20% for system processes)
Both init containers and main containers must have identical resource requests and limits.
Task 3: Edit the Deployment
Edit the python-webapp deployment and add resource requests and limits to both the init container (init-setup ) and the main container (python-app ).

After successfully editing the deployment, scale it back to 3 replicas.

Verify that all 3 pods are in Running state and have the correct resource configuration:

Try it yourself first!
✅ Solution (expand to view)
Kubernetes Resource Configuration - Imperative Commands
📊 Given Information
Total node01 Allocatable Resource:

CPU: 1 core (1000m)
Memory: 1948940Ki ÷ 1024 = 1803.26171875 Mi
Currently Allocated Resources (by other workloads):

CPU: 125m (12%)
Memory: 100Mi (5%)
📋 Requirements
The deployment will run 3 pods
Resources must be divided evenly across all 3 pods
Add 20% overhead to avoid node instability (reserve 20% for system processes)
Both init containers and main containers must have identical resource requests and limits
🧮 Calculation Steps
1. Calculate available resources (after 20% system overhead):
Available CPU = 1000m × 0.8 = 800m
Available Memory = 1803.26171875 Mi × 0.8 = 1442.609375 Mi
2. Subtract currently allocated resources:
CPU remaining = 800m - 125m = 675m
Memory remaining = 1442.609375 Mi - 100Mi = 1342.609375 Mi
3. Calculate per-pod resources (divide by 3 pods):
CPU per pod = 675m ÷ 3 = 225m
Memory per pod = 1342.609375 Mi ÷ 3 = 447.536458333 Mi
4. Round the values:
CPU: 225m → You can use 225m or any value below (e.g., 200m, 150m)
Memory: 447.54Mi → You can use 447Mi, 448Mi, or any value below (e.g., 400Mi, 350Mi)
5. Maximum allowed resources per container:
CPU: Must not exceed 225m (anything at or below is accepted)
Memory: Must not exceed 448Mi (anything at or below is accepted)
6. Resources for each container:
init-setup container: ≤ 225m CPU, ≤ 448Mi memory
python-app container: ≤ 225m CPU, ≤ 448Mi memory
🛠️ Implementation Steps (Imperative Commands)
```bash
Step 1: Scale down deployment
kubectl scale deployment python-webapp -n python-ml-ns --replicas=0
Verify:
```
```bash
kubectl get deployment python-webapp -n python-ml-ns
kubectl get pods -n python-ml-ns
Step 2: Calculate resources
Given:
```
Total CPU: 1000m, Total Memory: 1803.26171875 Mi
Currently allocated: CPU 125m, Memory 100Mi
System overhead: 20%, Number of pods: 3
Calculation:

Allocate node01 CPU = 1000m × 0.8 = 800m
Allocate node01 Memory = 1803.26171875 Mi × 0.8 = 1442.609375 Mi

Subtract allocated CPU = 800m - 125m = 675m
Subtract allocated Memory = 1442.609375 Mi - 100Mi = 1342.609375 Mi

Per Pod CPU = 675m ÷ 3 = 225m
Per Pod Memory = 1342.609375 Mi ÷ 3 = 447.54 Mi ≈ 447Mi (or 448Mi)
```bash
Step 3: Set resources using imperative commands
kubectl set resources deployment python-webapp \
  -n python-ml-ns \
  --requests=cpu=225m,memory=447Mi \
  --limits=cpu=225m,memory=447Mi
```

```bash
Step 4: Scale back to 3 replicas
kubectl scale deployment python-webapp -n python-ml-ns --replicas=3
```

```bash
Step 5: Verify pods are running
kubectl get pods -n python-ml-ns
kubectl wait --for=condition=ready pod -l app=python-webapp -n python-ml-ns --timeout=120s
Expected output: All 3 pods with status Running and READY 1/1
```

Step 6: Verify resource configuration
POD=$(kubectl get pod -n python-ml-ns -l app=python-webapp -o jsonpath='{.items[0].metadata.name}')

# Check init container resources
kubectl get pod $POD -n python-ml-ns -o jsonpath='{.spec.initContainers[0].resources}' | jq

# Check main container resources
kubectl get pod $POD -n python-ml-ns -o jsonpath='{.spec.containers[0].resources}' | jq

# Check QoS class (should be Guaranteed)
kubectl get pod $POD -n python-ml-ns -o jsonpath='{.status.qosClass}'
Expected output:

{
  "limits": {
    "cpu": "225m",
    "memory": "447Mi"
  },
  "requests": {
    "cpu": "225m",
    "memory": "447Mi"
  }
}
QoS Class: Guaranteed

📝 Alternative: Single-line Commands
Scale down:

kubectl scale deployment python-webapp -n python-ml-ns --replicas=0
Set resources for main container:

kubectl set resources deployment python-webapp -n python-ml-ns --containers=python-app --requests=cpu=225m,memory=447Mi --limits=cpu=225m,memory=447Mi
Set resources for init container:

kubectl set resources deployment python-webapp -n python-ml-ns --containers=init-setup --requests=cpu=225m,memory=447Mi --limits=cpu=225m,memory=447Mi
Scale up:

kubectl scale deployment python-webapp -n python-ml-ns --replicas=3
Verify:

kubectl get pods -n python-ml-ns -w
✅ Verification Checklist
✅ Deployment scaled to 0, then back to 3
✅ init-setup has resources configured
✅ python-app has resources configured
✅ Both containers have identical requests and limits
✅ All 3 pods are Running
✅ Pods have Guaranteed QoS class
✅ Resources per container: ≤ 225m CPU, ≤ 448Mi memory
📊 Final Resource Allocation Summary
Resource Type	Calculation	Value
Total Allocatable CPU	-	1000m
After 20% overhead	1000m × 0.8	800m
Minus allocated	800m - 125m	675m
Per pod	675m ÷ 3	225m

Total Allocatable Memory	-	1803.26 Mi
After 20% overhead	1803.26 Mi × 0.8	1442.61 Mi
Minus allocated	1442.61 Mi - 100Mi	1342.61 Mi
Per pod	1342.61 Mi ÷ 3	447 Mi
Total for 3 pods: 675m CPU, 1341Mi Memory
Remaining on node: 125m CPU, ~101Mi Memory

```bash
echo $(((1000*80/100 - 125)/3))
echo $((((1846524*80/100 - 100*1024)/3)/1024))
```
---

CKA: Analyze and Deploy NetworkPolicy
📚 Official Kubernetes Documentation:

Network Policies
Declare Network Policy
NetworkPolicy API Reference
🏢 Context
Your security team has prepared several NetworkPolicy YAML files, but you need to identify and deploy the correct policy that implements the principle of least privilege while ensuring the frontend can communicate with the backend.

There are two existing Deployments:

Frontend in the namespace frontend
Backend in the namespace backend
Several NetworkPolicy YAML files already exist in the directory: /root/network-policies

❓ Problem Statement
Task:

Examine the NetworkPolicy YAML files in /root/network-policies
Identify the NetworkPolicy that allows ingress traffic from the Frontend Pods to the Backend Pods
The selected policy must allow only the required communication and must be the least permissive
Deploy the selected NetworkPolicy to the cluster
Requirements:

Frontend Pods must be able to communicate with Backend Pods
Pods from any other namespace must not be allowed access to the Backend Pods
No additional ports or Pod sources should be allowed
Do not modify any existing Pods or Deployments
Try it yourself first!

✅ Solution (expand to view)

```yaml
Step 1: List and examine available NetworkPolicy files

ls -l /root/network-policies/
Step 2: Analyze each policy

Let's examine all policies:

for policy in /root/network-policies/policy*.yaml; do
  echo "=== $(basename $policy) ==="
  cat $policy
  echo ""
done
Step 3: Detailed Policy Analysis

Policy 1 Analysis:

ingress:
- from:
  - podSelector: {}  # ❌ Empty selector
    ports:
    - protocol: TCP
      port: 8080
Verdict: ❌ TOO PERMISSIVE

Empty podSelector: {} allows ALL pods in the backend namespace
Doesn't restrict by namespace
Problem: Any pod in backend namespace can access backend pods
Policy 2 Analysis:

ingress:
- from:
  - namespaceSelector:
      matchLabels:
        name: frontend      # ✅ Selects frontend namespace
    podSelector:
      matchLabels:
        app: frontend       # ✅ Selects app=frontend pods
    ports:
    - protocol: TCP
      port: 8080           # ✅ Only required port
Verdict: ✅ CORRECT - LEAST PERMISSIVE

Uses BOTH namespaceSelector AND podSelector
Allows only pods that are:
In the frontend namespace AND
Have label app=frontend
Only allows port 8080
This is the most restrictive and secure option
Policy 3 Analysis:

ingress:
- from:
  - namespaceSelector:
      matchLabels:
        name: frontend
    podSelector:
      matchLabels:
        app: frontend
  - ipBlock:               # ❌ Unnecessary external access
      cidr: 172.16.0.0/16
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 443            # ❌ Unnecessary port
Verdict: ❌ TOO PERMISSIVE

Includes ipBlock which allows traffic from external IP range 172.16.0.0/16
Allows multiple ports (8080 and 443)
Problem: Opens backend to external network and unnecessary ports
Policy 4 Analysis:

ingress:
- from:
  - namespaceSelector:
      matchLabels:
        name: frontend     # ✅ Namespace selector present
    # ❌ Missing podSelector
    ports:
    - protocol: TCP
      port: 8080
Verdict: ❌ TOO PERMISSIVE

Only has namespaceSelector, missing podSelector
Allows ALL pods in the frontend namespace, not just app=frontend pods
Problem: Any pod in frontend namespace can access backend (not least permissive)
Policy 5 Analysis:

ingress:
- from:
  - podSelector:
      matchLabels:
        app: frontend      # ❌ Only podSelector
    # ❌ Missing namespaceSelector
    ports:
    - protocol: TCP
      port: 8080
Verdict: ❌ WRONG - WON'T WORK

Only has podSelector without namespaceSelector
podSelector alone only matches pods in the same namespace (backend)
Problem: Frontend pods are in a different namespace, so this won't allow them
```

Step 4: Comparison Summary

Policy	namespaceSelector	podSelector	Ports	ipBlock	Verdict
policy1	❌ No	❌ Empty {}	8080	No	Too Permissive
policy2	✅ Yes (frontend)	✅ Yes (app=frontend)	8080	No	✅ CORRECT
policy3	✅ Yes	✅ Yes	8080, 443	❌ Yes	Too Permissive
policy4	✅ Yes (frontend)	❌ Missing	8080	No	Too Permissive
policy5	❌ No	✅ Yes (app=frontend)	8080	No	Won't Work
Step 5: Deploy the correct NetworkPolicy (Policy 2)

```bash
kubectl apply -f /root/network-policies/policy2.yaml
Verify deployment:

kubectl get networkpolicy -n backend
kubectl describe networkpolicy backend-network-policy -n backend
Step 6: Verify namespace and pod labels

# Check namespace labels
kubectl get namespace frontend --show-labels

# Check pod labels
kubectl get pods -n frontend --show-labels
kubectl get pods -n backend --show-labels
```

Step 7: Test the NetworkPolicy

Test 1: Frontend should have access (PASS)

echo "=== Test 1: Frontend to Backend (should SUCCEED) ==="
FRONTEND_POD=$(kubectl get pod -n frontend -l app=frontend -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n frontend $FRONTEND_POD -- curl -s --max-time 5 backend.backend.svc.cluster.local:8080 | grep -o "<title>.*</title>"
Test 2: Other namespace should be blocked (PASS)

echo "=== Test 2: Other namespace to Backend (should FAIL) ==="
OTHER_POD=$(kubectl get pod -n other -l app=other -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n other $OTHER_POD -- curl -s --max-time 5 backend.backend.svc.cluster.local:8080 && echo "❌ ALLOWED" || echo "✅ BLOCKED (correct)"

Step 8: Understanding why Policy 2 is correct
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend                    # Targets backend pods
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:              # ✅ Requirement 1: Namespace
        matchLabels:
          name: frontend
      podSelector:                    # ✅ Requirement 2: Specific pods
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080                      # ✅ Only required port
```
Why this is the least permissive:

✅ namespaceSelector + podSelector combined: Source must be in frontend namespace AND have app=frontend label
✅ No ipBlock: Doesn't allow external network access
✅ Single port: Only allows port 8080, no extras
✅ Specific labels: No empty selectors or wildcards
✅ Implicit deny: Everything else is automatically blocked
The key insight: Using both namespaceSelector and podSelector in the same from item creates an AND condition, making it the most restrictive and secure option.

Step 9: View the effective policy

# Get full policy details
kubectl get networkpolicy backend-network-policy -n backend -o yaml

# Verify which pods are selected
kubectl get pods -n backend -l app=backend --show-labels

# Check ingress rules
kubectl get networkpolicy backend-network-policy -n backend -o jsonpath='{.spec.ingress[0].from}' | jq
Verification checklist:

✅ Policy 2 identified as correct (most restrictive)
✅ Deployed to backend namespace
✅ Uses BOTH namespaceSelector AND podSelector
✅ Frontend pods can access backend:8080
✅ Other namespace pods are blocked
✅ Only port 8080 allowed
✅ No ipBlock or external access
✅ Least permissive principle applied

----

CKA: Horizontal Pod Autoscaler Configuration
📚 Official Kubernetes Documentation: Kubernetes Documentation - Horizontal Pod Autoscaler

🏢 Context
You are working 🧑‍💻 on an IoT Sensor API Platform that experiences variable traffic patterns throughout the day. The platform needs to scale automatically based on resource utilization to maintain performance while optimizing costs.

A Deployment named sensor-api is already running in the iot-sys namespace with 12 replicas. The metrics-server has been installed and configured for you.

### ❓ Question
A Deployment named sensor-api is running in the iot-sys namespace.

You must configure autoscaling for this Deployment by creating an HPA called sensor-hpa that can scale between 2 and 8 replicas.

The HPA should use both CPU and memory utilization, with each metric targeting 80% utilization.

Adding stabilizationWindowSeconds: 5 in the HPA ensures the replicas scale down smoothly from 12 to 2 , since the 12 pods were running unnecessarily without traffic.

Try it yourself first!
✅ Solution (expand to view)
Create the HPA YAML file:

vi /iot-platform/sensor-hpa.yaml
Add the following configuration:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: sensor-hpa
  namespace: iot-sys
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: sensor-api
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 5
```
Apply the HPA:

```yaml
kubectl apply -f /iot-platform/sensor-hpa.yaml
Verify the HPA creation:

kubectl get hpa sensor-hpa -n iot-sys
Check detailed HPA status:

kubectl describe hpa sensor-hpa -n iot-sys
Monitor the HPA behavior (you should see it scale down to 2 replicas):

watch -n 2 kubectl get hpa,deployment -n iot-sys
You can also check the current metrics:

kubectl top pods -n iot-sys
Expected result: The HPA should be created and will scale the deployment down from 12 to 2 replicas since there's minimal load on the pods.
```
