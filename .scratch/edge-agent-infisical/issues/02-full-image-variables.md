# Image variables hold full references

Status: resolved

- `host/`, `nginx/`, `edge-agent/`: `PORTAINER_VERSION` (tag only, with in-file default) replaced by `PORTAINER_IMAGE` / `PORTAINER_AGENT_IMAGE` (full pinned reference, `:?` required, no default).
- `nginx/`: literal `nginx:1.31.3-alpine` moved to `NGINX_IMAGE`.
- Same versions as before. `.env.example`, READMEs and `SECURITY_HARDENING.md` updated.
- Users must update their `.env` (rename and use the full reference).
- Infisical sidecar images bumped to `infisical/cli:0.44.15` and `busybox:1.38.0-musl` (unreleased in git, so no separate ticket).
