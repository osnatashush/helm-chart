{{/*
Expand the name of the chart.
*/}}
{{- define "nominatim.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nominatim.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if .Values.appName }}
{{- $name = .Values.appName }}
{{- end }}
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
{{- define "nominatim.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nominatim.labels" -}}
helm.sh/chart: {{ include "nominatim.chart" . }}
{{ include "nominatim.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nominatim.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nominatim.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nominatim.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nominatim.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Compute the effective region configuration.

Priority:
1) If nominatimRegion matches a regionPresets entry, use that preset.
2) Else, fall back to .Values.regionConfig (backward compatibility).

Returns YAML of the selected config.
*/}}
{{- define "nominatim.effectiveRegionConfig" -}}
{{- $selected := default "south-africa" .Values.nominatimRegion -}}
{{- $presets := .Values.regionPresets | default dict -}}
{{- if hasKey $presets $selected -}}
{{- toYaml (index $presets $selected) -}}
{{- else -}}
{{- toYaml .Values.regionConfig -}}
{{- end -}}
{{- end }}

{{/*
Generate the StatefulSet name with region
*/}}
{{- define "nominatim.statefulsetName" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s-%s-statefulset" (include "nominatim.fullname" .) $rc.name }}
{{- end }}

{{/*
Generate the service name with region
*/}}
{{- define "nominatim.serviceName" -}}
{{- if .Values.service.nameOverride }}
{{- .Values.service.nameOverride }}
{{- else }}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s-%s" (include "nominatim.fullname" .) $rc.name }}
{{- end }}
{{- end }}

{{/*
Generate the internal service name with region
*/}}
{{- define "nominatim.internalServiceName" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s-%s-internal" (include "nominatim.fullname" .) $rc.name }}
{{- end }}

{{/*
Generate the PVC name with region
*/}}
{{- define "nominatim.pvcName" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s-%s-efs-claim" (include "nominatim.fullname" .) $rc.name }}
{{- end }}

{{/*
Generate the PV name with region
*/}}
{{- define "nominatim.pvName" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s-%s-efs-pv" (include "nominatim.fullname" .) $rc.name }}
{{- end }}

{{/*
Generate the app label with region
*/}}
{{- define "nominatim.appLabel" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s-%s-app" (include "nominatim.fullname" .) $rc.name }}
{{- end }}

{{/*
Generate the liveness probe path with test coordinates
*/}}
{{- define "nominatim.livenessPath" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "/reverse?lat=%s&lon=%s&format=json" $rc.testCoordinates.lat $rc.testCoordinates.lon }}
{{- end }}

{{/*
Generate the PostgreSQL subPath with region
*/}}
{{- define "nominatim.postgresqlSubPath" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s/postgresql" $rc.countryCode }}
{{- end }}

{{/*
Generate the flatnode subPath with region
*/}}
{{- define "nominatim.flatnodeSubPath" -}}
{{- $rc := (include "nominatim.effectiveRegionConfig" . | fromYaml) -}}
{{- printf "%s/flatnode" $rc.countryCode }}
{{- end }}
