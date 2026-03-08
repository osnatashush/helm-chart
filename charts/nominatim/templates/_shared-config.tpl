{{/*
Shared Configuration System
This template provides functions to resolve {{Values.key}} syntax using a shared configuration file
*/}}

{{/*
Load shared configuration from values passed via --values shared-config.yaml or from centralConfig
The shared-config.yaml should be in your ArgoCD repository and contain top-level keys
that will be merged into .Values, or use the centralConfig section in values.yaml
*/}}
{{- define "shared.config" -}}
{{- $context := . -}}
{{- if hasKey $context "context" -}}
{{- $context = .context -}}
{{- end -}}
{{/* Try to get shared config from .Values.centralConfig first, then from top-level .Values */}}
{{- $sharedConfig := dict -}}

{{/* First priority: centralConfig section */}}
{{- if hasKey $context.Values "centralConfig" -}}
{{- range $key, $value := $context.Values.centralConfig -}}
{{- if $value -}}
{{- $_ := set $sharedConfig $key $value -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Second priority: top-level values (for backward compatibility) */}}
{{- if hasKey $context.Values "namespace" -}}
{{- $_ := set $sharedConfig "namespace" $context.Values.namespace -}}
{{- end -}}
{{- if hasKey $context.Values "domain" -}}
{{- $_ := set $sharedConfig "domain" $context.Values.domain -}}
{{- end -}}
{{- if hasKey $context.Values "environment" -}}
{{- $_ := set $sharedConfig "environment" $context.Values.environment -}}
{{- end -}}
{{- if hasKey $context.Values "region" -}}
{{- $_ := set $sharedConfig "region" $context.Values.region -}}
{{- end -}}
{{- if hasKey $context.Values "client" -}}
{{- $_ := set $sharedConfig "client" $context.Values.client -}}
{{- end -}}

{{/* Add any other top-level values that might be passed */}}
{{- range $key, $value := $context.Values -}}
{{- if and (typeIs "string" $value) (not (hasKey $sharedConfig $key)) (not (eq $key "centralConfig")) -}}
{{- $_ := set $sharedConfig $key $value -}}
{{- end -}}
{{- end -}}

{{- if $sharedConfig -}}
{{- toYaml $sharedConfig -}}
{{- else -}}
{{/* Fallback values if shared config is not provided */}}
namespace: "default"
domain: "example.com"
environment: "dev"
region: "us-east-1"
{{- end -}}
{{- end }}

{{/*
Resolve a templated value using shared configuration
Usage: {{ include "shared.resolve" (dict "value" "{{Values.namespace}}-dev" "context" .) }}
*/}}
{{- define "shared.resolve" -}}
{{- $value := .value -}}
{{- $context := .context -}}
{{- if and (typeIs "string" $value) (contains "{{Values." $value) -}}
{{- $sharedConfig := include "shared.config" . | fromYaml -}}
{{- $resolved := $value -}}
{{- range $key, $val := $sharedConfig -}}
{{- $placeholder := printf "{{Values.%s}}" $key -}}
{{- $resolved = $resolved | replace $placeholder (toString $val) -}}
{{- end -}}
{{- $resolved -}}
{{- else -}}
{{- $value -}}
{{- end -}}
{{- end }}

{{/*
Get a specific shared configuration value
Usage: {{ include "shared.get" (dict "key" "namespace" "context" .) }}
*/}}
{{- define "shared.get" -}}
{{- $key := .key -}}
{{- $context := .context -}}
{{- $sharedConfig := include "shared.config" $context | fromYaml -}}
{{- index $sharedConfig $key -}}
{{- end }}

{{/*
Check if a value needs shared config resolution
*/}}
{{- define "shared.needsResolution" -}}
{{- $value := . -}}
{{- if and (typeIs "string" $value) (contains "{{Values." $value) -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end }}
