-- Worker DB (idempotent: re-run at every pod start by update-postgresql.sh)

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{{ .Values.global.database.worker.username }}') THEN
    CREATE ROLE {{ .Values.global.database.worker.username | quote }} LOGIN;
  END IF;
END
$$;

ALTER ROLE {{ .Values.global.database.worker.username | quote }} WITH ENCRYPTED PASSWORD :'worker_password';

SELECT 'CREATE DATABASE {{ .Values.global.database.worker.name | quote }} OWNER {{ .Values.global.database.worker.username | quote }}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{{ .Values.global.database.worker.name }}')\gexec

GRANT ALL PRIVILEGES ON DATABASE {{ .Values.global.database.worker.name | quote }} TO {{ .Values.global.database.worker.username | quote }};
