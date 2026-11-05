{{- with secret "__INFISICAL_PROJECT_ID__" "__INFISICAL_ENV__" "/" -}}
{{- range . -}}
{{- if or (eq .Key "PORTAINER_EDGE_ID") (eq .Key "PORTAINER_EDGE_KEY") -}}
{{ .Key }}={{ .Value }}
{{ end -}}
{{- end -}}
{{- end }}
# render-complete
