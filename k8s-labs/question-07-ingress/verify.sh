#!/usr/bin/env bash  
set -euo pipefail  
  
NS="echo-sound"  
  
fail() { echo "❌ $1"; exit 1; }  
pass() { echo "✅ $1"; }  
  
# Basic checks  
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS not found"  
kubectl -n "$NS" get deployment echoserver-deployment >/dev/null 2>&1 || fail "Deployment echoserver-deployment not found"  
  
ready="$(kubectl -n "$NS" get deploy echoserver-deployment -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)"  
[[ "${ready:-0}" -ge 1 ]] || fail "Deployment echoserver-deployment is not ready"  
  
# Service checks  
kubectl -n "$NS" get svc echo-service >/dev/null 2>&1 || fail "Service echo-service not found"  
  
stype="$(kubectl -n "$NS" get svc echo-service -o jsonpath='{.spec.type}')"  
[[ "$stype" == "NodePort" ]] || fail "Service type must be NodePort (got: $stype)"  
  
svc_port="$(kubectl -n "$NS" get svc echo-service -o jsonpath='{range .spec.ports[*]}{.port}{" "}{end}')"  
echo "$svc_port" | grep -qw "8080" || fail "Service port 8080 not found"  
  
target_port="$(kubectl -n "$NS" get svc echo-service -o jsonpath='{range .spec.ports[?(@.port==8080)]}{.targetPort}{"\n"}{end}' | head -n1)"  
[[ "$target_port" == "8080" ]] || fail "targetPort for service port 8080 must be 8080 (got: $target_port)"  
  
node_port="$(kubectl -n "$NS" get svc echo-service -o jsonpath='{range .spec.ports[?(@.port==8080)]}{.nodePort}{"\n"}{end}' | head -n1)"  
[[ -n "$node_port" ]] || fail "NodePort not allocated on echo-service:8080"  
  
# Endpoints should exist  
ep_ips="$(kubectl -n "$NS" get endpoints echo-service -o jsonpath='{.subsets[*].addresses[*].ip}')"  
[[ -n "$ep_ips" ]] || fail "echo-service has no endpoints"  
  
# Ingress checks  
kubectl -n "$NS" get ingress echo >/dev/null 2>&1 || fail "Ingress echo not found"  
  
rules="$(kubectl -n "$NS" get ingress echo -o jsonpath='{range .spec.rules[*]}{.host}{" "}{range .http.paths[*]}{.path}{" "}{.backend.service.name}{" "}{.backend.service.port.number}{"\n"}{end}{end}')"  
echo "$rules" | grep -q "^example\.org /echo echo-service 8080$" || fail "Ingress rule must be example.org /echo -> echo-service:8080"  
  
# Ensure host mapping and port-forward available for curl test  
if ! grep -qE '(^|[[:space:]])example\.org([[:space:]]|$)' /etc/hosts; then  
  echo "127.0.0.1 example.org" >> /etc/hosts  
fi  
  
if ! pgrep -f "kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80" >/dev/null 2>&1; then  
  nohup kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80 --address 0.0.0.0 \  
    >/tmp/ingress-pf.log 2>&1 &  
  sleep 2  
fi  
  
# Final functional check  
ok=0  
for _ in {1..25}; do  
  code="$(curl -o /dev/null -s -w "%{http_code}" http://example.org/echo || true)"  
  if [[ "$code" == "200" ]]; then  
    ok=1  
    break  
  fi  
  sleep 2  
done  
  
[[ "$ok" -eq 1 ]] || fail "curl check failed: expected 200 from http://example.org/echo"  
  
pass "All checks passed."