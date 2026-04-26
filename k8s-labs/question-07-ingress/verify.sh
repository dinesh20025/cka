#!/usr/bin/env bash  
set -euo pipefail  
  
NS="echo-sound"  
  
fail() {  
  echo "❌ $1"  
  exit 1  
}  
  
pass() {  
  echo "✅ $1"  
}  
  
# 1) Namespace + base deployment check  
kubectl get ns "${NS}" >/dev/null 2>&1 || fail "Namespace ${NS} nahi mila"  
kubectl -n "${NS}" get deploy echoserver-deployment >/dev/null 2>&1 || fail "Base deployment echoserver-deployment missing"  
  
# 2) Service checks  
kubectl -n "${NS}" get svc echo-service >/dev/null 2>&1 || fail "Service echo-service nahi mila"  
  
svc_type="$(kubectl -n "${NS}" get svc echo-service -o jsonpath='{.spec.type}')"  
[[ "${svc_type}" == "NodePort" ]] || fail "Service type NodePort hona chahiye, mila: ${svc_type}"  
  
port_line="$(kubectl -n "${NS}" get svc echo-service -o jsonpath='{range .spec.ports[*]}{.port}:{.targetPort}:{.nodePort}{"\n"}{end}')"  
echo "${port_line}" | grep -q '^8080:8080:' || fail "echo-service me port 8080 -> targetPort 8080 mapping missing"  
  
# 3) Endpoints check (service actually backing pods)  
ep_ips="$(kubectl -n "${NS}" get endpoints echo-service -o jsonpath='{.subsets[*].addresses[*].ip}' || true)"  
[[ -n "${ep_ips}" ]] || fail "echo-service ke endpoints nahi bane (pod not ready / selector mismatch)"  
  
# 4) Ingress checks  
kubectl -n "${NS}" get ingress echo >/dev/null 2>&1 || fail "Ingress echo nahi mila"  
  
rule_dump="$(kubectl -n "${NS}" get ingress echo -o jsonpath='{range .spec.rules[*]}{.host}{"|"}{range .http.paths[*]}{.path}{":"}{.backend.service.name}{":"}{.backend.service.port.number}{"\n"}{end}{end}')"  
echo "${rule_dump}" | grep -q '^example.org|/echo:echo-service:8080$' || fail "Ingress rule expected: example.org /echo -> echo-service:8080"  
  
# 5) Ingress controller availability  
kubectl -n ingress-nginx get deploy ingress-nginx-controller >/dev/null 2>&1 || fail "ingress-nginx-controller deployment missing"  
  
# 6) Ensure port-forward running for functional test  
if ! pgrep -f "kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80" >/dev/null 2>&1; then  
  nohup kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 80:80 --address 127.0.0.1 >/tmp/ingress-pf.log 2>&1 &  
  sleep 2  
fi  
  
# 7) Functional test via ingress  
for _ in {1..25}; do  
  code="$(curl -s -o /dev/null -w "%{http_code}" -H "Host: example.org" http://127.0.0.1/echo || true)"  
  if [[ "${code}" == "200" ]]; then  
    pass "All checks passed 🎉"  
    exit 0  
  fi  
  sleep 2  
done  
  
fail "Functional test fail: expected HTTP 200 from ingress (Host: example.org, path: /echo)"