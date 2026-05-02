🔥 2-MINUTE UNIVERSAL DEBUG FLOW (REMEMBER THIS)
🚨 Step 1: kubectl fail ho raha hai?
kubectl get nodes

👉 Error:

connection refused
TLS timeout

➡️ Conclusion: API server down

🔍 Step 2: Check containers (NO GUESSWORK)
crictl ps -a

👉 Focus:

kube-apiserver
etcd
controller-manager
scheduler
🎯 Step 3: Identify culprit
Situation	Meaning
apiserver Exited ❌	start here
etcd down ❌	root issue
controller/scheduler down	secondary
🔎 Step 4: Logs = answer
crictl logs <container-id>

👉 Example jo tumhe mila:

dial tcp 10.0.0.100:2379

➡️ Tumhe hint mil gaya:

etcd connection problem

🛠️ Step 5: Fix config (NO RANDOM EDITS)
vi /etc/kubernetes/manifests/kube-apiserver.yaml

👉 Pattern:

wrong IP?
missing certs?
wrong flags?
🔄 Step 6: Restart kubelet
systemctl restart kubelet
✅ Step 7: Verify
kubectl get nodes
