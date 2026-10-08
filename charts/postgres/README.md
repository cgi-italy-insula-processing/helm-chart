# postgres

Deploys a single PostgreSQL instance (official `postgres` image) as a StatefulSet. It hosts
two databases: one for the processing server and one for the worker.

## Required Secrets

The umbrella chart creates the Secrets in
[`templates/secrets/database-secrets.yaml`](../../templates/secrets/database-secrets.yaml)
from the `databaseSecrets` block:

```yaml
databaseSecrets:
  platformPassword: "password"
  workerPassword: "password"
  postgresPassword: "password"
```

> **Warning:** the defaults are literally `password`. Override them for every installation.

When this chart is installed on its own, the Secrets must already exist in the namespace,
otherwise the pod stays in `CreateContainerConfigError`. The names are rendered with `tpl`:

| Values                  | Default name                          | Key                  | Variable               |
|-------------------------|---------------------------------------|----------------------|------------------------|
| `secrets.platform.name` | `{{ .Release.Name }}-secret`          | `database-password`  | `PLATFORM_DB_PASSWORD` |
| `secrets.worker.name`   | `{{ .Release.Name }}-worker-secret`   | `worker-db-password` | `WORKER_DB_PASSWORD`   |
| `secrets.postgres.name` | `{{ .Release.Name }}-postgres-secret` | `postgres-password`  | `POSTGRES_PASSWORD`    |

The platform Secret also carries `database-username` (from `global.database.platform.username`).
The umbrella uses the same Secrets for `server` (`global.platform.dbsecretname`) and `worker`
(`worker.dbSecret.name`): change them together.

## Database initialisation

- `files/dbInit/*.sql` are Helm templates (role and database names come from
  `global.database.platform|worker`, defaults `platform`/`platform_v2` and
  `platform_worker`/`platform_worker`). They are rendered into the Secret
  `<release>-postgresql-initdb-secret` and mounted at `/opt/dbinit`.
- A `postStart` hook runs `files/update-postgresql.sh` at every container start. It waits for
  the server, then runs each script with `psql`, passing the passwords as psql variables
  (`:'platform_password'`, `:'worker_password'`). psql quotes them as SQL literals, so
  passwords may contain any character.
- The scripts are idempotent: they create the roles and databases when missing and always set
  the role passwords, so a password change in the Secrets is applied at the next restart.
  The pod is not restarted automatically: after changing `databaseSecrets` run
  `kubectl rollout restart statefulset <release>-postgres`, otherwise server and worker use
  the new password while the database roles still have the old one.
- The script uses `gosu`, which ships with the Debian-based `postgres` images only: do not
  switch `image.tag` to an `-alpine` variant.
- If the hook fails (missing passwords, server not ready within 120 s) the container is
  killed and restarted; the reason is reported as a `FailedPostStartHook` event.
- The scripts are not mounted in `/docker-entrypoint-initdb.d`, because the image entrypoint
  would run them without the password variables.

## Configuration

`files/postgresql.conf` is mounted read-only at `/etc/postgresql` and passed with
`-c config_file=...`. A checksum annotation restarts the pod when it changes, so settings
that need a restart (for example `max_connections`, from `maxDBConnection`) are applied.

## Persistence

With `persistence.enabled`, data lives in a PVC from `volumeClaimTemplates`
(`persistence.mountPath`, `subPath`). An empty `persistence.storageClass` uses the cluster
default StorageClass; `"-"` disables dynamic provisioning.
