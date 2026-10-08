# broker

Deploys an Apache ActiveMQ Classic broker used as the job queue between the processing
server, the worker and the event collector (OpenWire on port 61616).

## Credentials

Broker credentials are owned by the umbrella chart through `global.activemq`.
The broker chart consumes that Secret for the web console realm and for the HTTP
health probes; `server` and `worker` read the same Secret for their JMS connection.

```yaml
global:
  activemq:
    secretname: activemq-user-secret
    usersecretkey: username
    pwdsecretkey: password
    username: admin
    password: admin
```

The umbrella chart renders the Secret in
[`templates/secrets/activemq-secret.yaml`](../../templates/secrets/activemq-secret.yaml)
as a standard Kubernetes `Opaque` Secret named after `global.activemq.secretname`.
It contains three keys:

- the key named by `usersecretkey`, holding `username`
- the key named by `pwdsecretkey`, holding `password`
- `jetty-realm.properties`, generated from the same credentials as:

```text
<username>: <password>, admin
```

> **Warning:** override the default `admin`/`admin` for every installation.

## Security

The credentials protect the web console (port 8161) only. `files/conf/activemq.xml` defines
no authentication plugin, so JMS clients connect to the transport connectors without
credentials. The broker Service is `ClusterIP` and must not be exposed outside the cluster;
restrict in-cluster access (for example with a NetworkPolicy) if other workloads share the
cluster.
