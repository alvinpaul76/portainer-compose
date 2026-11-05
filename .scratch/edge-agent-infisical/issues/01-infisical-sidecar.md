# Edge agent: Infisical sidecar for Edge ID/Key

Status: resolved

- `edge-agent/` gets an `infisical-agent` sidecar (Universal Auth) rendering `PORTAINER_EDGE_ID`/`PORTAINER_EDGE_KEY` into a Docker-managed `shared_secrets` volume.
- `portainer/agent` is shell-less, so a one-shot `busybox-init` copies static busybox into `busybox_bin`; `agent` uses it as entrypoint to read the file, export `EDGE_ID`/`EDGE_KEY` and `exec ./agent` (wrapper verified in the real image).
- Removed `EDGE_ID`/`EDGE_KEY` from `environment:`; `.env.example` keeps them commented as moved to Infisical, adds `INFISICAL_CLI_IMAGE` and `BUSYBOX_IMAGE`.
- Added `infisical/` config + template, `.env.agent.example`, gitignore for `edge-agent/.env.agent`, README setup/ops/troubleshooting.
- `.infisical.yaml` (from `infisical init`, repo root) committed as is.
- Not done: reboot and offline-fallback tests need a real Infisical identity.
