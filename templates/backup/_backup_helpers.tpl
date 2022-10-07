{{/*
Renders a list of ssh known hosts to a string
Usage:
{{ include "netbox.backup.knownhosts" . | b64enc | quote }}
*/}}
{{- define "netbox.backup.knownhosts" -}}
{{-   range .Values.backup.sshKnownHosts }}
{{ . }}
{{-   end }}

{{- end -}}

{{/*
Renders a value that contains a config for borgmatic CronJob pod.
Usage:
{{ include "netbox.backup.config" . }}
*/}}
{{- define "netbox.backup.config" -}}
{{- $repos := list -}}
{{- if .Values.backup.persistence.localRepo.enabled -}}
{{-   $repos = append $repos "/mnt/borgmatic/netbox-backup" -}}
{{- end -}}
{{- if .Values.backup.remoteRepos -}}
{{-   $repos = concat $repos .Values.backup.remoteRepos -}}
{{- end -}}
{{- if lt (len (default (list) $repos)) 1 -}}
{{-   fail "Please set up at least one remote repo (.Values.backup.remoteRepos) or enable the local backup repo (.Values.backup.persistence.localRepo.enabled) !" -}}
{{- end -}}
location:
  source_directories:
    {{- if .Values.persistence.enabled }}
    - "/opt/netbox/netbox/media"
    {{ end -}}
    {{ if .Values.reportsPersistence.enabled -}}
    - "/opt/netbox/netbox/reports"
    {{ end }}
  repositories:
    {{- range $repos }}
    - {{ . | quote }}
    {{- end }}
{{- if .Values.backup.config.location }}
{{ omit .Values.backup.config.location "source_directories" "repositories" | toYaml | indent 2 }}
{{ end -}}

{{- if .Values.backup.config }}
{{ omit .Values.backup.config "location" "hooks" | toYaml }}
{{ end -}}

hooks:
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
{{- if .Values.backup.config.hooks }}
{{ omit .Values.backup.config.hooks "postgresql_databases" | toYaml | indent 2 }}
{{- end }}
{{ end }}
