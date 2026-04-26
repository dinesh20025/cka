Create a new Ingress resource named **echo** in **echo-sound** namespace.  
  
## Tasks  
  
1. Expose deployment with a service named **echo-service** on `http://example.org/echo`  
   - Service port: `8080`  
   - Service type: `NodePort`  
  
2. Create Ingress **echo** so that:  
   - host = `example.org`  
   - path = `/echo`  
   - backend service = `echo-service:8080`  
  
3. This command should return `200`:  
  
```bash  
curl -o /dev/null -s -w "%{http_code}\n" http://example.org/echo  