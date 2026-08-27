{{/* Chart name. */}}
{{- define "drupal.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Resource base name: the requested naming scheme is the release name. */}}
{{- define "drupal.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "drupal.componentName" -}}
{{- $component := .component | trimPrefix "-" | trimSuffix "-" -}}
{{- $maxReleaseLength := sub 62 (len $component) | int -}}
{{- $releaseName := include "drupal.fullname" .root | trunc $maxReleaseLength | trimSuffix "-" -}}
{{- printf "%s-%s" $releaseName $component | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "drupal.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | quote }}
app.kubernetes.io/name: {{ include "drupal.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{- define "drupal.selectorLabels" -}}
{{- $labels := dict
      "app.kubernetes.io/name" (include "drupal.name" .root)
      "app.kubernetes.io/instance" .root.Release.Name
      "app.kubernetes.io/component" .component -}}
{{- $kind := "StatefulSet" -}}
{{- if eq .component "drupal" -}}
  {{- $kind = "Deployment" -}}
{{- end -}}
{{- $name := include "drupal.componentName" (dict "root" .root "component" .component) -}}
{{- $existing := lookup "apps/v1" $kind .root.Release.Namespace $name -}}
{{- if $existing -}}
  {{- $existingLabels := dig "spec" "selector" "matchLabels" (dict) $existing -}}
  {{- if $existingLabels -}}
    {{- $labels = $existingLabels -}}
  {{- end -}}
{{- end -}}
{{- toYaml $labels }}
{{- end }}

{{- define "drupal.protectionAnnotations" -}}
{{- range $key, $value := (.Values.commonAnnotations | default dict) }}
{{- if ne (toString $value) "" }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
meta.helm.sh/release-name: {{ .Release.Name | quote }}
meta.helm.sh/release-namespace: {{ .Release.Namespace | quote }}
{{- end }}

{{/*
Fail before an install can adopt or overwrite an existing object. A retained
PVC or Secret may be adopted during a reinstall when it still belongs to the
same release and namespace. During an upgrade, only objects carrying this
release's ownership metadata are accepted.
This check needs a connected cluster; Helm itself performs the same ownership
check when lookup is unavailable (for example, client-side helm template).
*/}}
{{- define "drupal.assertAvailable" -}}
{{- $root := .root -}}
{{- $existing := lookup .apiVersion .kind $root.Release.Namespace .name -}}
{{- if $existing -}}
  {{- $annotations := dig "metadata" "annotations" (dict) $existing -}}
  {{- $ownerName := get $annotations "meta.helm.sh/release-name" -}}
  {{- $ownerNamespace := get $annotations "meta.helm.sh/release-namespace" -}}
  {{- $ownedByRelease := and (eq $ownerName $root.Release.Name) (eq $ownerNamespace $root.Release.Namespace) -}}
  {{- if $root.Release.IsInstall -}}
    {{- if not (and (default false .allowAdoption) $ownedByRelease) -}}
      {{- fail (printf "%s %s/%s already exists and is not an adoptable retained resource of release %s/%s; refusing to overwrite it" .kind $root.Release.Namespace .name $root.Release.Namespace $root.Release.Name) -}}
    {{- end -}}
  {{- else -}}
    {{- if not $ownedByRelease -}}
      {{- fail (printf "%s %s/%s is not owned by release %s/%s; refusing to overwrite it" .kind $root.Release.Namespace .name $root.Release.Namespace $root.Release.Name) -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{- define "drupal.drupalName" -}}
{{ include "drupal.componentName" (dict "root" . "component" "drupal") }}
{{- end }}

{{- define "drupal.redisName" -}}
{{ include "drupal.componentName" (dict "root" . "component" "redis") }}
{{- end }}

{{- define "drupal.databaseName" -}}
{{ include "drupal.componentName" (dict "root" . "component" "db") }}
{{- end }}

{{- define "drupal.databaseAuthUsername" -}}
{{- .Release.Name | replace "-" "_" | trunc 32 | trimSuffix "_" -}}
{{- end }}

{{- define "drupal.databaseAuthDatabase" -}}
{{- printf "%sdb" (include "drupal.databaseAuthUsername" . | trunc 62 | trimSuffix "_") -}}
{{- end }}

{{- define "drupal.drupalServiceAccountName" -}}
{{- default (include "drupal.drupalName" .) .Values.serviceAccounts.drupalName }}
{{- end }}

{{- define "drupal.redisServiceAccountName" -}}
{{- default (include "drupal.redisName" .) .Values.serviceAccounts.redisName }}
{{- end }}

{{- define "drupal.databaseServiceAccountName" -}}
{{- default (include "drupal.databaseName" .) .Values.serviceAccounts.databaseName }}
{{- end }}

{{- define "drupal.drupalSecretName" -}}
{{- include "drupal.drupalName" . }}
{{- end }}

{{- define "drupal.httpAuthSecretName" -}}
{{- printf "%s-http-auth" (include "drupal.drupalName" .) }}
{{- end }}

{{- define "drupal.httpAuthEnabled" -}}
{{- if .Values.drupal.basicAuth.enabled -}}true{{- else -}}false{{- end -}}
{{- end }}

{{/* Use credentials for local Drupal probes whenever Nginx Basic Auth is enabled. */}}
{{- define "drupal.drupalProbeHandler" -}}
{{- if eq (include "drupal.httpAuthEnabled" .) "true" -}}
exec:
  command:
    - /bin/sh
    - -ec
    - |-
      exec curl --fail --silent --show-error \
        --user "${HTPASSWD_USER}:${HTPASSWD_PWD}" \
        --output /dev/null \
        "${DRUPAL_HEALTHCHECK_URL}"
{{- else -}}
httpGet:
  path: {{ .Values.drupal.probes.path | quote }}
  port: http
  scheme: HTTP
  httpHeaders:
    - name: Host
      value: "localhost"
{{- end -}}
{{- end }}

{{- define "drupal.redisSecretName" -}}
{{- include "drupal.redisName" . }}
{{- end }}

{{- define "drupal.smtpSecretName" -}}
{{- printf "%s-smtp" (include "drupal.drupalName" .) }}
{{- end }}

{{- define "drupal.databaseSecretName" -}}
{{- include "drupal.databaseName" . }}
{{- end }}

{{- define "drupal.drupalClaimName" -}}
{{- default (include "drupal.drupalName" .) .Values.drupal.persistence.existingClaim }}
{{- end }}

{{- define "drupal.redisClaimName" -}}
{{- default (include "drupal.redisName" .) .Values.redis.persistence.existingClaim }}
{{- end }}

{{- define "drupal.databaseClaimName" -}}
{{- default (include "drupal.databaseName" .) .Values.database.persistence.existingClaim }}
{{- end }}

{{/* Exact trusted-host regexes derived from names and literal host values. */}}
{{- define "drupal.drupalTrustedHostPatterns" -}}
{{- $hosts := list "localhost" "127.0.0.1" -}}
{{- $hosts = append $hosts .Values.drupal.externalHost -}}
{{- $hosts = append $hosts (include "drupal.drupalName" .) -}}
{{- range .Values.drupal.config.trustedHosts.additionalHosts -}}
  {{- $hosts = append $hosts . -}}
{{- end -}}
{{- $patterns := list -}}
{{- range ($hosts | uniq) -}}
  {{- $patterns = append $patterns (printf "^%s$" (. | regexQuoteMeta)) -}}
{{- end -}}
{{- join ", " $patterns -}}
{{- end }}

{{/* OpenShift image change trigger for a container in a pod template. */}}
{{- define "drupal.imageTrigger" -}}
{{- $from := dict "kind" "ImageStreamTag" "name" (printf "%s:%s" .name .tag) "namespace" .root.Release.Namespace -}}
{{- $trigger := dict "from" $from "fieldPath" (printf "spec.template.spec.containers[?(@.name==\"%s\")].image" .container) "paused" false -}}
{{- list $trigger | toJson -}}
{{- end }}

{{/* Public files path supplied by the compatible Drupal container image. */}}
{{- define "drupal.drupalPublicFilesMountPath" -}}
{{- "/var/www/html/web/sites/default/files" -}}
{{- end }}
