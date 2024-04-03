{{/*
Expand the name of the chart.
*/}}
{{- define "myk8schart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "myk8schart.fullname" -}}
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
{{- define "myk8schart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "myk8schart.labels" -}}
helm.sh/chart: {{ include "myk8schart.chart" . }}
{{ include "myk8schart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "myk8schart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "myk8schart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "myk8schart.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "myk8schart.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "myk8schart.ingress" }}
{{- range $key, $val := .Values.global.ingress.annotations }}
{{ $key }}: {{ $val | quote }}
{{- end }}
{{- end }}

{{- define "myk8schart.ingress.port" }}
number: {{ .Values.global.ingress.port }}
{{- end }}


{{- define "myk8schart.secretProviderName" }}
{{- printf "%s-%s" .Release.Name "azurekvsecretsprovider" | trimSuffix "-" | quote }}
{{- end }}

{{- define "myk8schart.secretProvider" }}
{{- if .Values.global.enabledAzureKeyVault }}
- secretRef:
    name: {{ include "myk8schart.secretProviderName" . }}
{{- end }}
{{- end }}

{{- define "myk8schart.secretProviderVolumeMount" }}
{{- if .Values.global.enabledAzureKeyVault }}
- name: keyvault-secrets
  mountPath: "/usr/keyvault-secrets"
  readOnly: true
{{- end }}
{{- end }}

{{- define "myk8schart.secretProviderVolume" }}
{{- if .Values.global.enabledAzureKeyVault }}
- name: keyvault-secrets
  csi:
    driver: secrets-store.csi.k8s.io
    readOnly: true
    volumeAttributes:
      secretProviderClass: {{ include "myk8schart.secretProviderName" . }}
{{- end }}
{{- end }}