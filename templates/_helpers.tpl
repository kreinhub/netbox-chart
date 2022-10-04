{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "netbox.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "netbox.fullname" -}}
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
Fully qualified app name for postgresql child chart.
*/}}
{{- define "netbox.postgresql.fullname" -}}
{{- if .Values.postgresql.fullnameOverride }}
{{- .Values.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "postgresql" .Values.postgresql.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Fully qualified app name for redis child chart.
*/}}
{{- define "netbox.redis.fullname" -}}
{{- if .Values.redis.fullnameOverride }}
{{- .Values.redis.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "redis" .Values.redis.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "netbox.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "netbox.labels" -}}
helm.sh/chart: {{ include "netbox.chart" . }}
{{ include "netbox.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "netbox.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netbox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "netbox.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "netbox.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the Secret that contains the PostgreSQL password
*/}}
{{- define "netbox.postgresql.secret" -}}
{{- if and .Values.postgresql.enabled .Values.postgresql.existingSecret -}}
{{ .Values.postgresql.existingSecret }}
{{- else if .Values.postgresql.enabled -}}
{{ include "netbox.postgresql.fullname" . }}
{{- else if .Values.externalDatabase.existingSecretName -}}
{{ .Values.externalDatabase.existingSecretName }}
{{- else -}}
{{ .Values.existingSecret | default (include "netbox.fullname" .) }}
{{- end -}}
{{- end }}

{{/*
Name of the key in Secret that contains the PostgreSQL password
*/}}
{{- define "netbox.postgresql.secretKey" -}}
{{- if .Values.postgresql.enabled -}}
postgresql-password
{{- else if .Values.externalDatabase.existingSecretName -}}
{{ .Values.externalDatabase.existingSecretKey }}
{{- else -}}
db_password
{{- end -}}
{{- end }}

{{/*
Name of the Secret that contains the Redis tasks password
*/}}
{{- define "netbox.tasksRedis.secret" -}}
  {{- if .Values.redis.enabled }}
    {{- if .Values.redis.auth.existingSecret }}
      {{- .Values.redis.auth.existingSecret }}
    {{- else }}
      {{- include "netbox.redis.fullname" . }}
    {{- end }}
  {{- else if .Values.tasksRedis.existingSecretName }}
    {{- .Values.tasksRedis.existingSecretName }}
  {{- else }}
    {{- .Values.existingSecret | default (include "netbox.fullname" .) }}
  {{- end }}
{{- end }}

{{/*
Name of the key in Secret that contains the Redis tasks password
*/}}
{{- define "netbox.tasksRedis.secretKey" -}}
{{- if .Values.redis.enabled -}}
redis-password
{{- else if .Values.tasksRedis.existingSecretName -}}
{{ .Values.tasksRedis.existingSecretKey }}
{{- else -}}
redis_tasks_password
{{- end -}}
{{- end }}

{{/*
Name of the Secret that contains the Redis cache password
*/}}
{{- define "netbox.cachingRedis.secret" -}}
  {{- if .Values.redis.enabled }}
    {{- if .Values.redis.auth.existingSecret }}
      {{- .Values.redis.auth.existingSecret }}
    {{- else }}
      {{- include "netbox.redis.fullname" . }}
    {{- end }}
  {{- else if .Values.cachingRedis.existingSecretName }}
    {{- .Values.cachingRedis.existingSecretName }}
  {{- else }}
    {{- .Values.existingSecret | default (include "netbox.fullname" .) }}
  {{- end }}
{{- end }}

{{/*
Name of the key in Secret that contains the Redis cache password
*/}}
{{- define "netbox.cachingRedis.secretKey" -}}
{{- if .Values.redis.enabled -}}
redis-password
{{- else if .Values.cachingRedis.existingSecretName -}}
{{ .Values.cachingRedis.existingSecretKey }}
{{- else -}}
redis_cache_password
{{- end -}}
{{- end }}

{{/*
Volumes that need to be mounted for .Values.extraConfig entries
*/}}
{{- define "netbox.extraConfig.volumes" -}}
{{- range $index, $config := .Values.extraConfig -}}
- name: extra-config-{{ $index }}
  {{- if $config.values }}
  configMap:
    name: {{ include "netbox.fullname" $ }}
    items:
      - key: extra-{{ $index }}.yaml
        path: extra-{{ $index }}.yaml
  {{- else if $config.configMap }}
  configMap:
    {{- toYaml $config.configMap | nindent 4 }}
  {{- else if $config.secret }}
  secret:
    {{- toYaml $config.secret | nindent 4 }}
  {{- end }}
{{ end -}}
{{- end }}

{{/*
Volume mounts for .Values.extraConfig entries
*/}}
{{- define "netbox.extraConfig.volumeMounts" -}}
{{- range $index, $config := .Values.extraConfig -}}
- name: extra-config-{{ $index }}
  mountPath: /run/config/extra/{{ $index }}
  readOnly: true
{{ end -}}
{{- end }}

{{/*
Renders a value that contains template.
Usage:
{{ include "netbox.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "netbox.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}

{{/*
Renders a list of ssh known hosts to a string
Usage:
{{ include "netbox.backup.knownhosts" . | b64enc | quote }}
*/}}
{{- define "netbox.backup.knownhosts" -}}
  {{- range .Values.backup.sshKnownHosts -}}
    {{ . }}
  {{- end -}}
{{- end -}}

{{/*
Renders a value that contains a config for borgmatic CronJob pod.
Usage:
{{ include "netbox.backup.config" . }}
*/}}
{{- define "netbox.backup.config" -}}
location:
  source_directories:
    {{- if .Values.persistence.enabled -}}
    - "/opt/netbox/netbox/media"
    {{- end -}}
    {{- if .Values.reportsPersistence.enabled -}}
    - "/opt/netbox/netbox/reports"
    {{- end -}}
  repositories:
    {{- if .Values.backup.persistence.localRepo.enabled -}}
    - "/mnt/borgmatic"
    {{- end -}}
    {{- if .Values.backup.remoteRepos -}}
    {{-   range .Values.backup.remoteRepos -}}
    - {{ . | quote }}
    {{-   end -}}
    {{- end -}}
{{- omit (default dict "" "" .Values.backup.config.location) "source_directories" "repositories" | toYaml | indent 2 -}}

{{- omit (default dict "" "" .Values.backup.config) "location" "hooks" | toYaml -}}

hooks:
{{- omit (default dict "" "" .Values.backup.config.hooks) "postgresql_databases" | toYaml | indent 2 -}}
  postgresql_databases:
    {{- if .Values.postgresql.enabled }}
    - name: {{ .Values.postgresql.postgresqlDatabase | quote }}
      hostname: {{ include "netbox.postgresql.fullname" . | quote }}
      port: {{ .Values.postgresql.service.port | int }}
      username: {{ .Values.postgresql.postgresqlUsername | quote }}
    {{- else -}}
    - name: {{ .Values.externalDatabase.database | quote }}
      hostname: {{ .Values.externalDatabase.host | quote }}
      port: {{ .Values.externalDatabase.port | int }}
      username: {{ .Values.externalDatabase.username | quote }}
    {{- end }}
      password: ${PGPASSWORD}
      format: tar
{{- end -}}

