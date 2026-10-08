{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "postgres.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a deterministic fully qualified app name.
*/}}
{{- define "postgres.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "postgres.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "postgres.labels" -}}
app.kubernetes.io/name: {{ include "postgres.name" . }}
helm.sh/chart: {{ include "postgres.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Get the initialization scripts Secret name.
*/}}
{{- define "postgres.initdbScriptsSecret" -}}
{{- printf "%s" (tpl .Values.initdbScriptsSecret $) -}}
{{- end -}}

{{/* Create the Service name. */}}
{{- define "postgres.serviceName" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 55 | trimSuffix "-" }}-service
{{- end -}}

{{/*
Get the storage class 
*/}}
{{- define "postgres.storageClass" -}}
{{- if .Values.persistence.storageClass -}}
        {{- if (eq "-" .Values.persistence.storageClass) -}}
            {{- printf "storageClassName: \"\"" -}}
        {{- else }}
            {{- printf "storageClassName: %s" .Values.persistence.storageClass -}}
        {{- end -}}
{{- end -}}
{{- end -}}
