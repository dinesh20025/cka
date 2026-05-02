https://killercoda.com/7e2fa581-e0aa-4908-8b26-459efaa15a9ba/scenario/16-reconfigure-deployment-nodeport-scenario
   
   4  kubectl get deployments
    5  kubectl get deployments -n sp-culator
    6  kubectl get deployment front-end -n sp-culator
   10  kubectl -n sp-culator get deploy front-end -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'  
   12  kubectl get deployment front-end -n sp-culator -o yaml
   13  kubectl edit deployment front-end -n sp-culator
   14  kubectl -n sp-culator expose deploy front-end --name=front-end-svc --port=80 --target-port=80 --type=NodePort
   15  kubectl -n sp-culator get deploy front-end -o yaml | grep -A8 -n "name: nginx"  
   16  kubectl -n sp-culator get svc front-end-svc -o wide  
   17  kubectl -n sp-culator describe svc front-end-svc | egrep "Type:|Port:|NodePort:|Endpoints:"  

   # Kubernetes Task: Reconfigure Deployment and Expose via NodePort  
  
## Question  
  
An existing deployment named `front-end` is running in the `sp-culator` namespace, but it is not correctly configured to expose its container port.  
  
### Tasks  
1. Reconfigure the `front-end` deployment to expose port `80/TCP` for its `nginx` container.    
2. Create a new Service named `front-end-svc`.    
3. The service must expose container port `80/TCP`.    
4. Configure the service as type `NodePort` to make it accessible on the node's IP.  
  
---  
  
## Answer  
  
### Step 1: Verify deployment and container name  
kubectl -n sp-culator get deploy front-end -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'

---

### Step 2: Patch deployment to expose container port 80/TCP
kubectl -n sp-culator patch deploy front-end -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","ports":[{"containerPort":80,"protocol":"TCP"}]}]}}}}'

---

###  Step 3: Create NodePort service front-end-svc
kubectl -n sp-culator expose deploy front-end --name=front-end-svc --port=80 --target-port=80  --type=NodePort  

---

kubectl -n sp-culator get deploy front-end -o yaml | grep -A8 -n "name: nginx"  
kubectl -n sp-culator get svc front-end-svc -o wide  
kubectl -n sp-culator describe svc front-end-svc | egrep "Type:|Port:|NodePort:|Endpoints:"  

---

Optional: Edit YAML manually instead of patch

kubectl -n sp-culator edit deploy front-end  
Add this under the nginx container:

---

ports:  
- containerPort: 80  
  protocol: TCP  
Then save and exit, and create the service using Step 3.

---

## question for Apply a taint to a node and schedule a pod with the correct toleration

```bash
k get nodes

k describe node | grep -i taint

k taint node controlplane IT=Kiddie:NoSchedule

k describe node | grep -i taint

k run pod-toleration --image=redis --dry-run=client -o yaml > pod-toleration.yaml

vi pod-toleration.yaml

k apply -f pod-toleration.yaml

k get po

k describe po pod-toleration
```
---

🛠️ Kubernetes Control Plane Recovery (etcd Migration Issue)
📌 Problem Statement
A single-node kubeadm cluster was migrated to a new machine and became non-functional:


Control plane was down ❌


Node was in NotReady state ❌


kubectl was not working ❌


Root Cause Hint
The cluster was previously using an external etcd, but the new setup should use local etcd (kubeadm default).

🔍 Symptoms
```bash
kubectl get nodes
```
The connection to the server <IP>:6443 was refused

```bash
crictl ps -a


kube-apiserver → Exited ❌


kube-controller-manager → Exited ❌


kube-scheduler → Exited ❌


etcd → Running ✅

```

🧠 Root Cause
kube-apiserver was still configured to connect to an old external etcd endpoint:
--etcd-servers=https://10.0.0.100:2379
Additionally, etcd TLS configuration was commented out, preventing secure communication.

🛠️ Solution
🔧 Step 1: Fix kube-apiserver configuration
Edit the static pod manifest:
vi /etc/kubernetes/manifests/kube-apiserver.yaml

❌ Incorrect Configuration
--etcd-servers=https://10.0.0.100:2379#--etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt#--etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt#--etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key

✅ Correct Configuration
--etcd-servers=https://127.0.0.1:2379--etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt--etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt--etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key

🔄 Step 2: Restart kubelet
systemctl restart kubelet

kubelet will automatically recreate static pods


⏳ Step 3: Verify Control Plane Components
crictl ps
Expected:


kube-apiserver → Running ✅


kube-controller-manager → Running ✅


kube-scheduler → Running ✅


etcd → Running ✅



🔍 Step 4: Verify Cluster Status
kubectl get nodes
Expected:
controlplane   Ready

🔍 Step 5: Verify System Pods
kubectl get pods -n kube-system
All pods should be in Running state.

🧠 Key Learnings


Kubernetes control plane depends heavily on etcd connectivity


Wrong etcd endpoint = complete cluster failure


Static pod manifests are located at:
/etc/kubernetes/manifests/


kubelet automatically manages static pods



🔥 Troubleshooting Flow (CKA Cheat Sheet)
kubectl not working    ↓Check containers → crictl ps    ↓Check kube-apiserver logs    ↓Look for etcd connection errors    ↓Fix kube-apiserver.yaml    ↓Restart kubelet    ↓Cluster restored ✅

🚀 Final Outcome


Control plane restored ✅


Node status → Ready ✅


All system pods running ✅

```bash

k get nod
    4  ls /etc/kubernetes
    5  ls /etc/kubernetes/manifests/
    6  cd /etc/kubernetes/manifests/
    7  cat kube-apiserver.yaml
    8  clear
    9  systemctl status kubelet
   10  clear
   11  ls
   12  crictl ps -a
   13  cat kube-controller-manager.yaml
   14  vi kube-controller-manager.yaml
   15  crictl ps -a
   16  k get po
   17  cat kube-controller-manager.yaml
   18  crictl ps -a | grep kube-apiserver
   19  crictl logs 6f9eeb0cff981
   20  crictl logs 49b2c64240197
   21  cat kube-apiserver.yaml
   22  vi kube-apiserver.yaml
   23  crictl ps -a | grep kube-apiserver
   24  crictl ps -a
   25  crictl logs bf7a56045c1c3
   26  systemctl restart kubelet
   27  crictl ps
   28  kubectl get po
   29  kubectl get node

```



🎯 One-Line Summary

Misconfigured etcd endpoint caused API server failure, fixing it restored the entire cluster.








