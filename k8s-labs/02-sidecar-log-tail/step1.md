# Add a Sidecar Container

Update the existing deployment **`wordpress`** in the `default` namespace by adding a sidecar container to the existing pod.

## Requirements

| Field | Value |
|---|---|
| Container name | `sidecar` |
| Image | `busybox:stable` |
| Command | `/bin/sh -c "tail -f /var/log/wordpress.log"` |
| Shared volume mount path | `/var/log` |

- Add a shared **emptyDir** volume to the pod
- Mount the volume at `/var/log` in **both** the `monitor` container and the `sidecar` container
- This makes `wordpress.log` accessible to both containers

## Hints

Check the current state of the deployment:
```
kubectl get deployment wordpress -o yaml
```

Edit the deployment:
```
kubectl edit deployment wordpress
```

After saving, verify both containers are running:
```
kubectl get pods
```

Check the sidecar is streaming logs:
```
kubectl logs deployment/wordpress -c sidecar
```
