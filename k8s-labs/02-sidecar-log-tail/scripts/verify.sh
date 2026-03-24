#!/bin/bash

DEPLOYMENT="wordpress"
NAMESPACE="default"
PASS=true

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; PASS=false; }

# 1. Deployment exists
if kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" &>/dev/null; then
  pass "Deployment '$DEPLOYMENT' exists in namespace '$NAMESPACE'"
else
  fail "Deployment '$DEPLOYMENT' not found in namespace '$NAMESPACE'"
  exit 1
fi

DEPLOY_JSON=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o json)

# 2. Container named 'sidecar' exists
SIDECAR_EXISTS=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
names = [c['name'] for c in d['spec']['template']['spec']['containers']]
print('true' if 'sidecar' in names else 'false')
")
if [ "$SIDECAR_EXISTS" = "true" ]; then
  pass "Container 'sidecar' found in deployment"
else
  fail "Container 'sidecar' not found in deployment"
  exit 1
fi

# 3. Sidecar uses busybox:stable
SIDECAR_IMAGE=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for c in d['spec']['template']['spec']['containers']:
    if c['name'] == 'sidecar':
        print(c.get('image', ''))
")
if [ "$SIDECAR_IMAGE" = "busybox:stable" ]; then
  pass "Sidecar image is 'busybox:stable'"
else
  fail "Sidecar image is '$SIDECAR_IMAGE', expected 'busybox:stable'"
fi

# 4. Sidecar runs: /bin/sh -c "tail -f /var/log/wordpress.log"
CMD_OK=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for c in d['spec']['template']['spec']['containers']:
    if c['name'] == 'sidecar':
        full = ' '.join(c.get('command', []) + c.get('args', []))
        ok = '/bin/sh' in full and '-c' in full and 'tail -f /var/log/wordpress.log' in full
        print('true' if ok else 'false')
")
if [ "$CMD_OK" = "true" ]; then
  pass "Sidecar command is correct"
else
  fail "Sidecar command incorrect — expected: /bin/sh -c 'tail -f /var/log/wordpress.log'"
fi

# 5. emptyDir volume exists and is mounted at /var/log in both containers
VOLUME_CHECK=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
spec = d['spec']['template']['spec']
empty_dirs = [v['name'] for v in spec.get('volumes', []) if 'emptyDir' in v]
sidecar_ok = any(
    m['mountPath'] == '/var/log' and m['name'] in empty_dirs
    for c in spec['containers'] if c['name'] == 'sidecar'
    for m in c.get('volumeMounts', [])
)
monitor_ok = any(
    m['mountPath'] == '/var/log'
    for c in spec['containers'] if c['name'] == 'monitor'
    for m in c.get('volumeMounts', [])
)
print(len(empty_dirs) > 0, sidecar_ok, monitor_ok)
")
read -r HAS_VOL SIDECAR_MNT MONITOR_MNT <<< "$VOLUME_CHECK"

[ "$HAS_VOL" = "True" ]     && pass "emptyDir volume exists"                        || fail "No emptyDir volume found in deployment"
[ "$SIDECAR_MNT" = "True" ] && pass "Sidecar has volume mounted at /var/log"        || fail "Sidecar missing volume mount at /var/log"
[ "$MONITOR_MNT" = "True" ] && pass "Monitor has volume mounted at /var/log"        || fail "Monitor missing volume mount at /var/log"

# 6. Pod is running with 2 ready containers
READY=$(kubectl get pods -n "$NAMESPACE" -l app=wordpress \
  -o jsonpath='{.items[0].status.containerStatuses[*].ready}' 2>/dev/null \
  | tr ' ' '\n' | grep -c "true" || true)

if [ "$READY" -ge 2 ]; then
  pass "Pod is running with $READY ready containers"
else
  fail "Pod does not have 2 ready containers (found: $READY) — run: kubectl get pods"
fi

echo ""
if [ "$PASS" = "true" ]; then
  echo "All checks passed!"
  exit 0
else
  echo "Some checks failed. Review the output above."
  exit 1
fi
