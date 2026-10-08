#!/bin/bash
set -e

# Wait for this container's Postgres to accept TCP connections instead of using a
# fixed "sleep". During the first initialisation the image's entrypoint runs a
# temporary server on the Unix socket only, so this waits for the final server.
for i in $(seq 1 60); do
  pg_isready -h 127.0.0.1 -U postgres -q && break
  if [ "$i" -eq 60 ]; then
    echo "postgres not ready after 120s" >&2
    exit 1
  fi
  sleep 2
done

if [[ -z "${PLATFORM_DB_PASSWORD:-}" || -z "${WORKER_DB_PASSWORD:-}" ]]; then
  echo "PLATFORM_DB_PASSWORD and WORKER_DB_PASSWORD must be set" >&2
  exit 1
fi

# The SQL scripts read the passwords as psql variables (:'platform_password',
# :'worker_password'): psql quotes them as SQL literals, so any character is safe.
for script in /opt/dbinit/*.sql; do
  [ -f "$script" ] || continue

  echo "Executing $script"

  gosu postgres psql -v ON_ERROR_STOP=1 -U postgres \
    -v platform_password="${PLATFORM_DB_PASSWORD}" \
    -v worker_password="${WORKER_DB_PASSWORD}" \
    -f "$script"
done
