# Kubernetes Ingress Setup (echo-sound namespace)  
  
## Objective  
Create a new **Ingress** resource named `echo` in namespace `echo-sound` and expose the app via service `echo-service`.  
  
---  
  
## 1) Verify Deployment  
  
kubectl get deploy -n echo-sound  

Example output:
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE  
echoserver-deployment   1/1     1            1           18s  

---  

## 2) Expose Deployment as NodePort Service

kubectl expose deployment echoserver-deployment -n echo-sound \  
  --name echo-service \  
  --port 8080 \  
  --target-port 8080 \  
  --type=NodePort  

  Check service:

  kubectl get svc -n echo-sound  

  Example output:


NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE  
echo-service   NodePort   10.96.105.216   <none>        8080:31392/TCP   10s  

---

## 3) Create Ingress Manifest

Create ingress.yaml:
```yaml
apiVersion: networking.k8s.io/v1  
kind: Ingress  
metadata:  
  name: echo  
  namespace: echo-sound  
spec:  
  ingressClassName: nginx  
  rules:  
    - host: example.org  
      http:  
        paths:  
          - path: /echo  
            pathType: Prefix  
            backend:  
              service:  
                name: echo-service  
                port:  
                  number: 8080
```


Apply it:
kubectl apply -f ingress.yaml  

Output:
ingress.networking.k8s.io/echo created  

---

## (4) Verify Ingress
kubectl get ingress -n echo-sound  

Example output:
NAME   CLASS   HOSTS         ADDRESS   PORTS   AGE  
echo   nginx   example.org             80      18s  

---

## (5) Verify Node Details

kubectl get nodes -o wide  

Example output:
NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP  
controlplane   Ready    control-plane   ...   v1.35.1   172.30.1.2    <none>  
node01         Ready    <none>          ...   v1.35.1   172.30.2.2    <none>  

---

## (6) Test Endpoint
Using Node internal IP and service NodePort:
NODE_IP=172.30.2.2  
NODE_PORT=31392  
  
curl -o /dev/null -s -w "%{http_code}\n" -H "HOST: example.org" http://${NODE_IP}:${NODE_PORT}/echo  

Expected result:
200










                  
