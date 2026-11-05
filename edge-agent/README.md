# Edge Agent variant

Portainer Edge Agent only. This node is managed remotely by an existing Portainer instance; there is no local UI. The agent polls the server outbound, so no inbound port is published.

## Files

- `docker-compose.yml` – the `agent` service (`EDGE=1` is set in the compose file).
- `infisical/` – agent config and secret template for the Infisical sidecar (committed; deployment values are substituted at start from `.env.agent`).
- `.env.agent.example` – copy to `.env.agent`, then `chmod 600 .env.agent` (see [Infisical secrets](#infisical-secrets)).
- `.env.example` – copy to `.env` and adjust. `agent_data` is bind-mounted at `${DEFAULT_STORAGE_FOLDER}/agent_data`; create it first with `sudo ./create_volumes.sh edge-agent` (run from the repo root).

## Environment variables

| Variable                       | Required | Purpose                                                  | Notes                                                                             |
| ------------------------------ | -------- | -------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `SHARED_DOCKER_NETWORK`        | Yes      | External network the agent joins                         | `cloudflared_shared-network`                                                      |
| `DEFAULT_STORAGE_FOLDER`       | Yes      | Host directory holding the `agent_data` bind mount       | `/storage/portainer`; created by `create_volumes.sh`.                             |
| `PORTAINER_AGENT_IMAGE`        | Yes      | Pinned agent image                                       | `portainer/agent:2.45.3`; keep in line with server.                               |
| `INFISICAL_CLI_IMAGE`          | Yes      | Pinned Infisical agent image                             | `infisical/cli:0.44.15`.                                                           |
| `BUSYBOX_IMAGE`                | Yes      | Pinned static busybox image                              | `busybox:1.38.0-musl`; must be a static build.                                    |
| `PORTAINER_EDGE_INSECURE_POLL` | No       | Allow non-TLS polling                                    | `1` only for development against a non-TLS server; keep `0` in production.        |
| `PORTAINER_LOG_LEVEL`          | No       | Agent log verbosity                                      | `INFO` in production; `DEBUG` may log sensitive request data.                     |
| `AGENT_CLUSTER_ADDR`           | Yes      | Agent cluster address                                    | `portainer-agent`.                                                                |

`PORTAINER_EDGE_ID` / `PORTAINER_EDGE_KEY` now live in Infisical, not `.env`.

## Infisical secrets

An `infisical-agent` sidecar logs in with Universal Auth and renders the Edge ID/Key into the `shared_secrets` volume. The Portainer image has no shell, so a one-shot `busybox-init` copies a static `busybox` into the `busybox_bin` volume; the `agent` service uses it to read the rendered file, export `EDGE_ID`/`EDGE_KEY`, then `exec ./agent`.

Prerequisites: an Infisical project with secrets `PORTAINER_EDGE_ID` and `PORTAINER_EDGE_KEY` at path `/`, and a read-only Universal Auth machine identity scoped to that project/env/path. Its credentials in `.env.agent` are the only secret left on disk.

| `.env.agent` variable                    | Fill in                                             |
| ---------------------------------------- | --------------------------------------------------- |
| `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`     | Machine identity client ID                          |
| `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET` | Machine identity client secret                      |
| `INFISICAL_ADDRESS`                      | Infisical URL (`https://app.infisical.com` or self-hosted) |
| `INFISICAL_PROJECT_ID`                   | Project ID                                          |
| `INFISICAL_ENV`                          | Environment slug (e.g. `prod`)                      |

Operations:

- After changing a secret in Infisical: `docker compose restart agent` (read only at start).
- Offline: the last rendered file stays in `shared_secrets`, so the agent still starts if Infisical is unreachable.
- Do not run `docker compose down -v` casually: it deletes that fallback file.

## Deploy

1. In the remote Portainer UI: Add Environment → Edge Agent → copy the generated Edge ID and Edge Key, and store them in Infisical as `PORTAINER_EDGE_ID` / `PORTAINER_EDGE_KEY`.
2. From the repository root:

```bash
cp edge-agent/.env.example edge-agent/.env
cp edge-agent/.env.agent.example edge-agent/.env.agent && chmod 600 edge-agent/.env.agent   # fill in
sudo ./create_volumes.sh edge-agent                # creates ${DEFAULT_STORAGE_FOLDER}/agent_data
docker network create cloudflared_shared-network   # skip if it already exists
cd edge-agent && docker compose up -d
```

3. The environment shows as "Up" in the remote UI once the reverse tunnel is established (a few seconds).

Never commit real Edge ID/Key values or `.env.agent`.

## Troubleshooting

- Agent crashes with `mkdir /data: read-only file system`: the container is `read_only`, so `agent_data:/data` must be present in the compose file's `volumes`.
- `docker compose logs infisical-agent`: a login error means wrong client ID/secret; a 404 or missing key means placeholder values in `.env.agent`, or a wrong secret name, project ID or env slug.
- `INFISICAL_CLI_IMAGE`/`BUSYBOX_IMAGE must be set`: add them to `.env` (see `.env.example`).
- `container name already in use` for the sidecar: it has no `container_name`; remove any added one.
- `PORTAINER_EDGE_ID missing`: the secret is absent from Infisical at path `/` for that env.
- Environment stays offline: check `docker compose logs` and that this node can reach the server URL embedded in the Edge Key.

See [`../SECURITY_HARDENING.md`](../SECURITY_HARDENING.md) for the hardening applied.
