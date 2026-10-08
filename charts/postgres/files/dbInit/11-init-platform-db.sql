-- Platform DB (idempotent: re-run at every pod start by update-postgresql.sh)

DO
$$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '{{ .Values.global.database.platform.username }}') THEN
    CREATE ROLE {{ .Values.global.database.platform.username | quote }} LOGIN;
  END IF;
END
$$;

ALTER ROLE {{ .Values.global.database.platform.username | quote }} WITH ENCRYPTED PASSWORD :'platform_password';

SELECT 'CREATE DATABASE {{ .Values.global.database.platform.name | quote }} OWNER {{ .Values.global.database.platform.username | quote }}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '{{ .Values.global.database.platform.name }}')\gexec

GRANT ALL PRIVILEGES ON DATABASE {{ .Values.global.database.platform.name | quote }} TO {{ .Values.global.database.platform.username | quote }};
