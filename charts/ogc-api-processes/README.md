# ogc-api-processes

Deploys the OGC API - Processes facade. It translates OGC API - Processes requests into
calls to the processing server REST API, so it is the external entry point of the stack.

## Configuration

The application configuration is the `properties` map of this chart, rendered (with `tpl`)
into the ConfigMap `<release>-ogcapi-config` and mounted as `/application.properties`.
The pod is restarted automatically when it changes (`checksum/config` annotation).
The umbrella `values.yaml` provides a working default; the keys that matter most:

| Key | Purpose |
|-----|---------|
| `server.servlet.context-path` | Context path of the API (`/ogcapi`); must match the Ingress path |
| `ogcapi.processes.insula.client.baseUrl` | Processing server REST API, in-cluster Service URL |
| `ogcapi.processes.insula.client.connectTimeout`, `readTimeout` | Timeouts (ms) of the calls to the server |
| `ogcapi.processes.security.enabled` | Must be `false`: the stack has no authentication |
| `ogcapi.processes.insula.searchApi.enabled` | Must be `false`: the processing server has no search endpoint |
| `ogcapi.processes.job.costEstimate.enabled` | Must be `false`: the processing server has no cost estimation |
| `ogcapi.processes.insula.getSubJobsApi.enabled` | Parent/sub-job links in job descriptions |
| `management.*` | Actuator on port 8081, used by the liveness and readiness probes |

## Ports

| Port | Use |
|------|-----|
| 8080 | API (Service port, Ingress backend) |
| 8081 | Actuator (`/actuator/health/liveness`, `/actuator/health/readiness`) |

## Resources

The image starts the JVM with `-Xmx4096m`, so the default memory limit is `5Gi`.
Lowering the limit below the heap size leads to OOM kills under load.
