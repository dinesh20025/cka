#!/bin/bash  
set -euo pipefail  
  
NS="echo-sound"  
  
fail() { echo "❌ $1"; exit 1; }  
pass() { echo "✅ $1"; }  
  
kubectl get ns "$NS" >/dev/null 2>&1 || fail "Namespace $NS not found"  
  
# Service checks  
kubectl -n "$NS" get svc echo-service >/dev/null 2>&1 || fail "Service echo-service not found"  
  
stype=$(kubectl -n "$NS" get svc echo-service -o jsonpath='{.spec.type}')  
[[ "$stype" == "NodePort" ]] || fail "Service type must be NodePort, got: $stype"  
  
port8080=$(kubectl -n "$NS" get svc echo-service -o jsonpath='{.spec.ports[?(@.port==8080)].port}')  
[[ "$port8080" == "8080" ]] || fail "Service port 8080 not configured"  
  
nodeport=$(kubectl -n "$NS" get svc echo-service -o jsonpath='{.spec.ports[?(@.port==8080)].nodePort}')  
[[ -n "${nodeport}" ]] || fail "NodePort not assigned on service port 8080"  
  
# Ingress checks  
kubectl -n "$NS" get ingress echo >/dev/null 2>&1 || fail "Ingress echo not found"  
  
rule=$(kubectl -n "$NS" get ingress echo -o jsonpath='{range .spec.rules[*]}{.host}{"|"}{range .http.paths[*]}{.path}{":"}{.backend.service.name}{":"}{.backend.service.port.number}{"\n"}{end}{end}')  
echo "$rule" | grep -q "^example.org|/echo:echo-service:8080$" || fail "Ingress rule must route example.org/echo -> echo-service:8080"  
  
# Endpoint check  
ep=$(kubectl -n "$NS" get endpoints echo-service -o jsonpath='{.subsets[*].addresses[*].ip}')  
[[ -n "$ep" ]] || fail "Service has no endpoints"  
  
# HTTP 200 check (with retries)  
ok=0  
for i in {1..20}; do  
  code=$(curl -o /dev/null -s -w "%{http_code}" http://example.org/echo || true)  
  if [[ "$code" == "200" ]]; then  
    ok=1  
    break  
  fi  
  sleep 3  
done  
[[ "$ok" -eq 1 ]] || fail "curl check failed, expected 200 on http://example.org/echo"  
  
pass "All checks passed"  