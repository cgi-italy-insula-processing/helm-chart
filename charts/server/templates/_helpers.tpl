{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "server.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a deterministic fully qualified app name.
*/}}
{{- define "server.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Create the Service name. */}}
{{- define "server.serviceName" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 55 | trimSuffix "-" }}-service
{{- end -}}

{{/*
Base URL of the job output links (platform.orchestrator.jobOutputs.baseUrl).
Order: .Values.jobOutputsBaseUrl, then the first ingress host (https when ingress.tls
is set), then the in-cluster Service. The API base path is appended to the last two.
*/}}
{{- define "server.jobOutputsBaseUrl" -}}
{{- if .Values.jobOutputsBaseUrl -}}
{{- .Values.jobOutputsBaseUrl | trimSuffix "/" -}}
{{- else if and .Values.ingress.enabled .Values.ingress.hosts -}}
{{- $scheme := ternary "https" "http" (not (empty .Values.ingress.tls)) -}}
{{- printf "%s://%s%s" $scheme (first .Values.ingress.hosts).host .Values.apiBasePath -}}
{{- else -}}
{{- printf "http://%s:%v%s" (include "server.serviceName" .) .Values.service.port .Values.apiBasePath -}}
{{- end -}}
{{- end -}}
