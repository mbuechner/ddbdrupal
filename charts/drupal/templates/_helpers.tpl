{{/* Chart name. */}}
{{- define "drupal.name" -}}
{{- $products := dict
      "ddbgo-production" "ddbgo"
      "ddbgo-test" "ddbgo"
      "ddbpro-production" "ddbpro"
      "ddbpro-test" "ddbpro" -}}
{{- get $products .Values.deploymentProfile | default .Chart.Name | trunc 63 | trimSuffix "-" }}
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
app.kubernetes.io/name: {{ include "drupal.name" .root | quote }}
app.kubernetes.io/instance: {{ .root.Release.Name | quote }}
app.kubernetes.io/component: {{ .component | quote }}
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

{{/* Curated deployment profiles; custom keeps repository and tag configurable. */}}
{{- define "drupal.drupalImageRepository" -}}
{{- $repositories := dict
      "ddbgo-production" "ghcr.io/mbuechner/ddbgo"
      "ddbgo-test" "ghcr.io/mbuechner/ddbgo"
      "ddbpro-production" "ghcr.io/deutsche-digitale-bibliothek/ddbpro"
      "ddbpro-test" "ghcr.io/deutsche-digitale-bibliothek/ddbpro" -}}
{{- if eq .Values.deploymentProfile "custom" -}}
{{- .Values.drupal.image.repository -}}
{{- else -}}
{{- get $repositories .Values.deploymentProfile -}}
{{- end -}}
{{- end }}

{{- define "drupal.drupalImageTag" -}}
{{- $tags := dict
      "ddbgo-production" "tagged"
      "ddbgo-test" "test"
      "ddbpro-production" "tagged"
      "ddbpro-test" "test" -}}
{{- if eq .Values.deploymentProfile "custom" -}}
{{- .Values.drupal.image.tag -}}
{{- else -}}
{{- get $tags .Values.deploymentProfile -}}
{{- end -}}
{{- end }}

{{/* Database identity derived from deployment profile/release. */}}
{{- define "drupal.databaseIdentity" -}}
{{- $products := dict
      "ddbgo-production" "ddbgo"
      "ddbgo-test" "ddbgo"
      "ddbpro-production" "ddbpro"
      "ddbpro-test" "ddbpro" -}}
{{- get $products .Values.deploymentProfile | default .Release.Name | replace "-" "_" | trunc 32 | trimSuffix "_" -}}
{{- end }}

{{- define "drupal.profileReleaseName" -}}
{{- $releases := dict
      "ddbgo-production" "ddbgo"
      "ddbgo-test" "ddbgo-t"
      "ddbpro-production" "ddbpro"
      "ddbpro-test" "ddbpro-t" -}}
{{- get $releases .Values.deploymentProfile -}}
{{- end }}

{{- define "drupal.drupalExternalHost" -}}
{{- $hosts := dict
      "ddbgo-production" "go.deutsche-digitale-bibliothek.de"
      "ddbgo-test" "go-t.deutsche-digitale-bibliothek.de"
      "ddbpro-production" "pro.deutsche-digitale-bibliothek.de"
      "ddbpro-test" "pro-t.deutsche-digitale-bibliothek.de" -}}
{{- get $hosts .Values.deploymentProfile | default .Values.drupal.externalHost -}}
{{- end }}

{{- define "drupal.databaseAuthUsername" -}}
{{- include "drupal.databaseIdentity" . -}}
{{- end }}

{{- define "drupal.databaseAuthDatabase" -}}
{{- printf "%sdb" (include "drupal.databaseIdentity" . | trunc 62 | trimSuffix "_") -}}
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
{{- if and .Values.drupal.basicAuth.username .Values.drupal.basicAuth.password -}}true{{- else -}}false{{- end -}}
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
{{- $hosts := list -}}
{{- if .Values.drupal.config.trustedHosts.allowLocalhost -}}
  {{- $hosts = append $hosts "localhost" -}}
  {{- $hosts = append $hosts "127.0.0.1" -}}
{{- end -}}
{{- $hosts = append $hosts (include "drupal.drupalExternalHost" .) -}}
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
