{{/*
Return the name of the chart
*/}}
{{- define "stash.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return the full name of the chart (release name + chart name)
*/}}
{{- define "stash.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "stash.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
