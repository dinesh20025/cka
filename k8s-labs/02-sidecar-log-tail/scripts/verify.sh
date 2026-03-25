#!/bin/bash

DEPLOYMENT="webapp"
NAMESPACE="default"
PASS=true

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; PASS=false; }

# 1. Deployment exists
if kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" &>/dev/null; then
  pass "Deployment '$DEPLOYMENT' exists"
else
  fail "Deployment '$DEPLOYMENT' not found"
  exit 1
fi

DEPLOY_JSON=$(kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" -o json)

# 2. Container named 'log-reader' exists
SIDECAR_EXISTS=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
names = [c['name'] for c in d['spec']['template']['spec']['containers']]
print('true' if 'log-reader' in names else 'false')
")
if [ "$SIDECAR_EXISTS" = "true" ]; then
  pass "Sidecar container 'log-reader' found"
else
  fail "Sidecar container 'log-reader' not found"
  exit 1
fi

# 3. log-reader uses busybox:1.36
SIDECAR_IMAGE=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for c in d['spec']['template']['spec']['containers']:
    if c['name'] == 'log-reader':
        print(c.get('image', ''))
")
if [ "$SIDECAR_IMAGE" = "busybox:1.36" ]; then
  pass "Sidecar image is 'busybox:1.36'"
else
  fail "Sidecar image is '$SIDECAR_IMAGE', expected 'busybox:1.36'"
fi

# 4. log-reader runs: /bin/sh -c "tail -f /var/log/application.log"
CMD_OK=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for c in d['spec']['template']['spec']['containers']:
    if c['name'] == 'log-reader':
        full = ' '.join(c.get('command', []) + c.get('args', []))
        ok = '/bin/sh' in full and '-c' in full and 'tail -f /var/log/application.log' in full
        print('true' if ok else 'false')
")
if [ "$CMD_OK" = "true" ]; then
  pass "Sidecar command is correct"
else
  fail "Sidecar command incorrect — expected: /bin/sh -c 'tail -f /var/log/application.log'"
fi

# 5. Shared volume mounted at /var/log in both containers
VOLUME_CHECK=$(echo "$DEPLOY_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
spec = d['spec']['template']['spec']
empty_dirs = [v['name'] for v in spec.get('volumes', []) if 'emptyDir' in v]
sidecar_ok = any(
    m['mountPath'] == '/var/log' and m['name'] in empty_dirs
    for c in spec['containers'] if c['name'] == 'log-reader'
    for m in c.get('volumeMounts', [])
)
webapp_ok = any(
    m['mountPath'] == '/var/log'
    for c in spec['containers'] if c['name'] == 'webapp'
    for m in c.get('volumeMounts', [])
)
print(len(empty_dirs) > 0, sidecar_ok, webapp_ok)
")
read -r HAS_VOL SIDECAR_MNT WEBAPP_MNT <<< "$VOLUME_CHECK"

[ "$HAS_VOL" = "True" ]    && pass "emptyDir volume exists"                          || fail "No emptyDir volume found"
[ "$SIDECAR_MNT" = "True" ] && pass "log-reader has volume mounted at /var/log"      || fail "log-reader missing volume mount at /var/log"
[ "$WEBAPP_MNT" = "True" ]  && pass "webapp has volume mounted at /var/log"          || fail "webapp missing volume mount at /var/log"

# 6. Pod running with 2 ready containers
READY=$(kubectl get pods -n "$NAMESPACE" -l app=webapp \
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
