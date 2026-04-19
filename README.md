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

### Step 2: Patch deployment to expose container port 80/TCP
kubectl -n sp-culator patch deploy front-end -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","ports":[{"containerPort":80,"protocol":"TCP"}]}]}}}}'

###  Step 3: Create NodePort service front-end-svc
kubectl -n sp-culator expose deploy front-end --name=front-end-svc --port=80 --target-port=80  --type=NodePort  

kubectl -n sp-culator get deploy front-end -o yaml | grep -A8 -n "name: nginx"  
kubectl -n sp-culator get svc front-end-svc -o wide  
kubectl -n sp-culator describe svc front-end-svc | egrep "Type:|Port:|NodePort:|Endpoints:"  

Optional: Edit YAML manually instead of patch

kubectl -n sp-culator edit deploy front-end  
Add this under the nginx container:


ports:  
- containerPort: 80  
  protocol: TCP  
Then save and exit, and create the service using Step 3.



