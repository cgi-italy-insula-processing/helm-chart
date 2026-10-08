# EOEPCA+ Processing building block Helm chart

Helm chart `eoepca` deploys an OGC API - Processes service with the processing back end
that runs the jobs as [Argo Workflows](https://argoproj.github.io/workflows/) on Kubernetes.

> **This chart does not include authentication or authorization.** Every exposed endpoint
> (OGC API, job output downloads, Argo UI, object storage) is anonymous by default. Protecting
> the installation (network policies, an authenticating reverse proxy, ingress
> authentication, private networking) is the responsibility of the operator. See
> [Security](#security) before exposing anything outside the cluster.

## Components

| Subchart | Enabled | Image | Role |
|----------|---------|-------|------|
| `ogc-api-processes` | yes | `ghcr.io/cgi-italy-insula-processing/com.cgi.eoss.ogc/ogc-api-processes:1.0.3-f0d8a5b7` | OGC API - Processes facade, external entry point (`/ogcapi`) |
| `server` | yes | `ghcr.io/cgi-italy-insula-processing/com.cgi.eoss.platform.core/server-core:1.48.0-84e09f86` | Processing server: services, job configurations, jobs, job outputs (REST API) |
| `worker` | yes | `.../worker-core:1.48.0-84e09f86`, `.../k8s-event-collector-core:1.48.0-84e09f86` | Turns queued jobs into Argo Workflows; the event collector reports pod and workflow status |
| (workflow steps) | - | `.../input-downloader-core:1.48.0-84e09f86`, `.../output-uploader-core:1.48.0-84e09f86` | Run inside every workflow: stage inputs in, upload outputs to object storage |
| `argo-workflows` | yes | `quay.io/argoproj/*:v3.5.5` | Workflow controller and UI |
| `broker` | yes | `apache/activemq-classic:6.1.7` | Job queue between server, worker and event collector |
| `postgres` | yes | `postgres:12` | Databases of the server and the worker |
| `minio` | yes | `ghcr.io/cgi-italy-insula-processing/minio:RELEASE.2021-02-14T04-01-33Z` | S3 object storage for job inputs and outputs. **Test only**, see [MinIO](#minio) |
| `docker-registry` | no | `registry:2.8.1` | Optional in-cluster container registry |

All images are public: no image pull secret is needed.

### Job flow

1. A client submits an execution to `ogc-api-processes`, which creates and launches a job
   configuration on the `server`.
2. The `server` queues the job on the `broker`.
3. The `worker` consumes it and creates an Argo Workflow in the `<release>-workflows`
   namespace: input download, processor step, output upload. Each job gets its own PVC.
4. The event collector watches the workflow pods and reports status changes to the `worker`
   through the `broker`.
5. Outputs are uploaded to object storage and served by the `server` at
   `<server base URL>/jobs/{jobId}/outputs/{outputId}`.

## Prerequisites

- Kubernetes 1.34 or newer (enforced by `kubeVersion` in `Chart.yaml`), with a **default StorageClass**: every PVC (broker, postgres,
  server, MinIO, per-job workflow volumes) relies on it unless a class is set explicitly.
- [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) for the default Ingress
  objects. The server Ingress uses a regular expression path
  (`nginx.ingress.kubernetes.io/use-regex`); ingress-nginx then treats every path of the
  same host as a regular expression.
- Helm 3.
- Cluster-admin rights at install time: the chart installs the Argo Workflows CRDs and
  ClusterRoles, and creates the `<release>-workflows` namespace.

## Installation

Create a values file with at least the overrides listed in
[Required configuration](#required-configuration), then:

```bash
helm install eoepca . --namespace eoepca --create-namespace -f my-values.yaml
```

The release namespace must not be named `<release>-workflows`: the chart creates that
namespace for the workflow pods.

`helm template` and `helm lint --strict` run offline against a default Kubernetes
version older than 1.34; pass it explicitly, for example
`helm template eoepca . --kube-version 1.34.0 -f my-values.yaml`.

Once the pods are ready, the OGC API is served at `http://<host>/ogcapi` and the
Swagger UI at `http://<host>/ogcapi/api/`.

> **Host names are placeholders.** Every Ingress defaults to an `example.com` host
> (`example.com`, `argo.example.com`, `minio.example.com`), and the job output links are built
> from the `server.ingress` host. Replace them with your own DNS names (see
> [Required configuration](#required-configuration)). To try the chart without DNS, keep the
> defaults and send the host explicitly, for example:
>
> ```bash
> curl -H "Host: example.com" http://<ingress-controller-address>/ogcapi/
> ```

## Required configuration

| Value | Default | Why |
|-------|---------|-----|
| `global.activemq.username`, `global.activemq.password` | `admin` / `admin` | Broker web console credentials, also used by server and worker |
| `global.storage.accesskey`, `global.storage.secretkey` | `accesskey` / `secretkey` | Object storage credentials (MinIO root user when MinIO is enabled) |
| `databaseSecrets.platformPassword`, `workerPassword`, `postgresPassword` | `password` | Database role passwords |
| `ogc-api-processes.ingress.hosts`, `server.ingress.hosts` | `example.com` | Public host name; keep them equal so output links and the OGC API share the host |
| `argo-workflows.server.ingress.hosts` | `argo.example.com` | Argo UI host, see [Argo Workflows UI](#argo-workflows-ui) |
| `minio.ingress.hosts` | `minio.example.com` | MinIO S3 API host, see [MinIO](#minio) |
| `*.ingress.tls` | `[]` | TLS configuration; with TLS on `server.ingress`, output links use `https` |

The default credentials are public. Never deploy them unchanged.

## Configuration notes

- **Application properties.** `server`, `worker` (including the input-downloader and
  output-uploader ConfigMaps and the event collector) and `ogc-api-processes` take a
  `properties` map that becomes their `application.properties`. The values are rendered with
  `tpl`, so `{{ .Release.Name }}` and other values can be referenced.
- **Job output links.** `platform.orchestrator.jobOutputs.baseUrl` is derived from
  `server.jobOutputsBaseUrl` when set, else from the first `server.ingress` host (https when
  `server.ingress.tls` is set), else from the in-cluster Service URL.
- **Storage classes.** No StorageClass is set: the cluster default is used. To pin one, set
  `broker.persistence.storageClass`, `postgres.persistence.storageClass`,
  `server.persistence.storageClass`, `minio.persistence.storageClass` and the worker property
  `platform.worker.workflow.legacy.persistentVolumeClaimStorageClass`.
- **Private processor images.** Workflow pods reference the pull secrets listed in
  `workflowPullSecrets`, which the chart creates in `<release>-workflows`. They must exist:
  Argo reads them to look up the entrypoint of the input-downloader and output-uploader images.
  The default `{"auths":{}}` carries no credentials; for private registries set
  `dockerconfigjson` to a `~/.docker/config.json` style document. If you rename them, update the
  worker properties `platform.worker.workflow.legacy.*ImagePullSecretName` and
  `argo-workflows.controller.rbac.secretWhitelist` (the only Secrets the Argo controller may
  read) to the same names.
- **Persistent data.** The broker, MinIO, server and postgres volumes carry
  `helm.sh/resource-policy: keep` and survive `helm uninstall`; delete the PVCs explicitly to
  remove the data. The Argo CRDs are removed on uninstall unless `argo-workflows.crds.keep` is
  `true`.

## Security

The chart ships no authentication or authorization layer. The operator decides how to
protect each entry point:

| Entry point | Default | Exposure |
|-------------|---------|----------|
| OGC API (`ogc-api-processes.ingress`) | enabled | Anonymous: anyone reaching it can deploy processes and run jobs |
| Job output downloads (`server.ingress`) | enabled | Anonymous, limited to `/jobs/{jobId}/outputs/{outputId}`; job ids are numeric and guessable |
| Argo Workflows UI (`argo-workflows.server.ingress`) | enabled | Anonymous **full access** with the default `authModes: ["server"]` |
| MinIO S3 API (`minio.ingress`) | enabled | Protected only by `global.storage` credentials |
| Broker | not exposed | No JMS authentication; the credentials protect the web console only |

### Argo Workflows UI

With `authModes: ["server"]` anyone who reaches the UI can create, edit and delete
workflows, which means running arbitrary containers in the cluster. Either:

- remove the Ingress (`argo-workflows.server.ingress.enabled: false`) and use
  `kubectl port-forward` when the UI is needed, or
- switch to token authentication with `argo-workflows.server.authModes: ["client"]`. The chart
  then creates a ServiceAccount, token Secret and RoleBinding (`argoUiUser.clusterRole`, default
  `edit`) and prints the command to retrieve the login token, or
- put an authenticating proxy in front of it.

### MinIO

The bundled MinIO is a 2021 release provided **for testing only**. It is not maintained, it
is exposed by an Ingress without authentication at the ingress level, and its credentials are
the shared `global.storage` keys. For production, disable it (`minio.enabled: false`) or
remove the subchart, and point the server, worker, input-downloader and output-uploader
properties (`endpoint`, `region`, bucket names) and `global.storage` at a managed
S3-compatible object store.

## Limitations

- Single user: processes and jobs are owned by a built-in default user.
- The broker runs without JMS authentication: server, worker and event collector connect to
  it unauthenticated. Keep its Service internal and restrict in-cluster access (for example
  with a NetworkPolicy) when the cluster is shared.
- `postgres:12` is end of life upstream; plan an upgrade path before production use.

## License

Apache License 2.0, see [LICENSE](LICENSE). Third-party Helm charts vendored under `charts/`
are listed in [NOTICE](NOTICE) with their origin and local modifications.
