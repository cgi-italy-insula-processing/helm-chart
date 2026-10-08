{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "docker-registry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "docker-registry.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Create the Service name. */}}
{{- define "docker-registry.serviceName" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 55 | trimSuffix "-" }}-service
{{- end -}}

{{- define "docker-registry.envs" -}}
- name: REGISTRY_HTTP_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ template "docker-registry.fullname" . }}-secret
      key: haSharedSecret

{{- if .Values.secrets.htpasswd }}
- name: REGISTRY_AUTH
  value: "htpasswd"
- name: REGISTRY_AUTH_HTPASSWD_REALM
  value: "Registry Realm"
- name: REGISTRY_AUTH_HTPASSWD_PATH
  value: "/auth/htpasswd"
{{- end }}

{{- if .Values.tlsSecretName }}
- name: REGISTRY_HTTP_TLS_CERTIFICATE
  value: /etc/ssl/docker/tls.crt
- name: REGISTRY_HTTP_TLS_KEY
  value: /etc/ssl/docker/tls.key
{{- end }}

- name: REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY
  value: "/var/lib/registry"

{{- if .Values.persistence.deleteEnabled }}
- name: REGISTRY_STORAGE_DELETE_ENABLED
  value: "true"
{{- end -}}

{{- with .Values.extraEnvVars }}
{{ toYaml . }}
{{- end -}}

{{- end -}}

{{- define "docker-registry.volumeMounts" -}}
- name: "{{ template "docker-registry.fullname" . }}-config"
  mountPath: "/etc/docker/registry"

{{- if .Values.secrets.htpasswd }}
- name: auth
  mountPath: /auth
  readOnly: true
{{- end }}

- name: data
  mountPath: /var/lib/registry

{{- if .Values.tlsSecretName }}
- mountPath: /etc/ssl/docker
  name: tls-cert
  readOnly: true
{{- end }}

{{- with .Values.extraVolumeMounts }}
{{ toYaml . }}
{{- end }}

{{- end -}}

{{- define "docker-registry.volumes" -}}
- name: {{ template "docker-registry.fullname" . }}-config
  configMap:
    name: {{ template "docker-registry.fullname" . }}-config

{{- if .Values.secrets.htpasswd }}
- name: auth
  secret:
    secretName: {{ template "docker-registry.fullname" . }}-secret
    items:
    - key: htpasswd
      path: htpasswd
{{- end }}

- name: data
  {{- if .Values.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ if .Values.persistence.existingClaim }}{{ .Values.persistence.existingClaim }}{{- else }}{{ template "docker-registry.fullname" . }}{{- end }}
  {{- else }}
  emptyDir: {}
  {{- end -}}

{{- if .Values.tlsSecretName }}
- name: tls-cert
  secret:
    secretName: {{ .Values.tlsSecretName }}
{{- end }}

{{- with .Values.extraVolumes }}
{{ toYaml . }}
{{- end }}
{{- end -}}
