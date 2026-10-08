# Docker Registry Helm Chart

This directory contains a Kubernetes chart to deploy a private Docker Registry.

## Prerequisites Details

* PV support on underlying infrastructure (if persistence is required)

## Chart Details

This chart will do the following:

* Implement a Docker registry deployment

## Storage

This chart supports a single storage model: the container's local filesystem, mounted
on a Kubernetes volume.

The registry always uses:

```text
REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry
```

The `data` volume is always mounted at `/var/lib/registry`.
When `persistence.enabled` is `true`, the volume is a PVC: `persistence.existingClaim`
when set, otherwise a PVC created by the chart with the configured `storageClass`,
`accessMode` and `size`. When `persistence.enabled` is `false`, the volume is an `emptyDir`.

Compared with the upstream chart, the `storage` selector and the remote storage backends
were removed, including their values, Secret keys and environment variables. Secret fields
not related to storage, such as `htpasswd` and `haSharedSecret`, are unchanged.
