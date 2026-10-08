{{/*
Expand the name of the chart.
*/}}
{{- define "ogc-api-processes.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
For EOEPCA+ charts resource names use Release.Name and the component name.
*/}}
{{- define "ogc-api-processes.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ogc-api-processes.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create the Service name. */}}
{{- define "ogc-api-processes.serviceName" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 55 | trimSuffix "-" }}-service
{{- end -}}

{{/*
Common labels
*/}}
{{- define "ogc-api-processes.labels" -}}
helm.sh/chart: {{ include "ogc-api-processes.chart" . }}
{{ include "ogc-api-processes.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ogc-api-processes.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ogc-api-processes.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "ogc-api-processes.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ogc-api-processes.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
