{{/*
Expand the name of the chart.
*/}}
{{- define "book-review.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "book-review.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "book-review.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "book-review.labels" -}}
helm.sh/chart: {{ include "book-review.chart" . }}
{{ include "book-review.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "book-review.selectorLabels" -}}
app.kubernetes.io/name: {{ include "book-review.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "book-review.frontend.labels" -}}
{{ include "book-review.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "book-review.frontend.selectorLabels" -}}
{{ include "book-review.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend labels
*/}}
{{- define "book-review.backend.labels" -}}
{{ include "book-review.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "book-review.backend.selectorLabels" -}}
{{ include "book-review.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
MongoDB labels
*/}}
{{- define "book-review.mongodb.labels" -}}
{{ include "book-review.labels" . }}
app.kubernetes.io/component: mongodb
{{- end }}

{{/*
MongoDB selector labels
*/}}
{{- define "book-review.mongodb.selectorLabels" -}}
{{ include "book-review.selectorLabels" . }}
app.kubernetes.io/component: mongodb
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "book-review.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "book-review.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get the proper image name
*/}}
{{- define "book-review.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $tag := .imageRoot.tag | toString -}}
{{- if .global.imageRegistry }}
    {{- printf "%s/%s:%s" .global.imageRegistry $repositoryName $tag -}}
{{- else if $registryName }}
    {{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
    {{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }} 