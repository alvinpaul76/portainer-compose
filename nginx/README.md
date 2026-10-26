# nginx variant – Portainer Server behind a reverse proxy

Portainer Server on a private internal network, fronted by nginx (`1.31.3-alpine`). Portainer publishes no ports and is not reachable from `shared-network`; only nginx is. This is the more locked-down server variant, intended for Cloudflare Tunnel or similar.

## Files

- `docker-compose.yml` – `portainer` and `nginx-proxy` services.
- `nginx.conf` – proxy config (websocket support, `/nginx-health` endpoint).
- `.env.example` – copy to `.env` and adjust.

## Environment variables

| Variable                 | Purpose                                                   | Default / typical value      |
| ------------------------ | --------------------------------------------------------- | ---------------------------- |
| `SHARED_DOCKER_NETWORK`  | External network nginx joins (required)                   | `cloudflared_shared-network` |
| `DEFAULT_STORAGE_FOLDER` | Base dir; data is bind-mounted at `<dir>/data` (required) | `/storage/portainer`         |
| `PORTAINER_VERSION`      | Pinned Portainer image tag                                | `2.45.3`                     |
| `NGINX_PORT`             | Host port for nginx (container 80), on 127.0.0.1          | `8080`                       |

## Deploy

From the repository root:

```bash
cp nginx/.env.example nginx/.env        # then edit
sudo ./create_volumes.sh nginx
docker network create cloudflared_shared-network   # skip if it already exists
cd nginx && docker compose up -d
```

Access:

- Host: `http://localhost:8080` (or your `NGINX_PORT`).
- From other containers on `shared-network` (e.g. `cloudflared`): `http://portainer-nginx:80`.

Portainer runs with `--http-enabled` here; this is safe only because HTTP is confined to the internal network. Terminate TLS at the tunnel or proxy in front of nginx.

## Edge tunnel

The compose file does not publish the Edge tunnel port (8000). If you need it, add `"8000:8000"` to the `portainer` service and attach an outward-facing network.

## Operate

Run inside `nginx/`:

```bash
docker compose ps          # nginx-proxy reports health via /nginx-health
docker compose logs
docker compose restart
docker compose down
```

See [`../SECURITY_HARDENING.md`](../SECURITY_HARDENING.md) for the hardening applied.
