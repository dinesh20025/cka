#!/usr/bin/env bash  
set -euo pipefail  
  
fail() {  
  echo "❌ $1"  
  exit 1  
}  
  
pass() {  
  echo "✅ $1"  
}  
  
# 1) Deployment exists  
kubectl get deployment wordpress >/dev/null 2>&1 || fail "deployment/wordpress not found"  
pass "deployment/wordpress exists"  
  
# 2) sidecar container exists  
containers=$(kubectl get deploy wordpress -o jsonpath='{.spec.template.spec.containers[*].name}')  
echo "$containers" | grep -qw sidecar || fail "container 'sidecar' not found in deployment/wordpress"  
pass "sidecar container exists"  
  
# 3) sidecar image is busybox:stable  
sidecar_image=$(kubectl get deploy wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].image}')  
case "$sidecar_image" in  
  busybox:stable|docker.io/busybox:stable|docker.io/library/busybox:stable) ;;  
  *) fail "sidecar image must be busybox:stable (found: $sidecar_image)" ;;  
esac  
pass "sidecar image is busybox:stable"  
  
# 4) sidecar command includes /bin/sh -c and tail of wordpress.log  
sidecar_cmd=$(kubectl get deploy wordpress -o jsonpath='{.spec.template.spec.containers[?(@.name=="sidecar")].command[*]} {.spec.template.spec.containers[?(@.name=="sidecar")].args[*]}')  
echo "$sidecar_cmd" | grep -q "/bin/sh" || fail "sidecar must use /bin/sh"  
echo "$sidecar_cmd" | grep -q -- "-c" || fail "sidecar must use -c"  
echo "$sidecar_cmd" | grep -q "tail -f /var/log/wordpress.log" || fail "sidecar must run: tail -f /var/log/wordpress.log"  
pass "sidecar command is correct"  
  
# 5) /var/log mounted in BOTH containers and shared volume name is same  
wp_vol=$(kubectl get deploy wordpress -o jsonpath='{range .spec.template.spec.containers[?(@.name=="wordpress")].volumeMounts[?(@.mountPath=="/var/log")]}{.name}{"\n"}{end}' | head -n1 || true)  
sc_vol=$(kubectl get deploy wordpress -o jsonpath='{range .spec.template.spec.containers[?(@.name=="sidecar")].volumeMounts[?(@.mountPath=="/var/log")]}{.name}{"\n"}{end}' | head -n1 || true)  
  
[ -n "${wp_vol:-}" ] || fail "wordpress container missing /var/log mount"  
[ -n "${sc_vol:-}" ] || fail "sidecar container missing /var/log mount"  
[ "$wp_vol" = "$sc_vol" ] || fail "containers do not share same volume at /var/log (wordpress=$wp_vol, sidecar=$sc_vol)"  
pass "shared /var/log volume mount is correct"  
  
echo "🎉 Verification successful"  
exit 0  
