# Host variant – Portainer Server

Portainer Server (UI + management backend) managing the local Docker engine. Publishes HTTPS only, bound to `127.0.0.1`.

## Files

- `docker-compose.yml` – the `portainer` service.
- `.env.example` – copy to `.env` and adjust.

## Environment variables

| Variable                 | Purpose                                                | Default / typical value      |
| ------------------------ | ------------------------------------------------------ | ---------------------------- |
| `SHARED_DOCKER_NETWORK`  | External network the container joins (required)        | `cloudflared_shared-network` |
| `DEFAULT_STORAGE_FOLDER` | Base dir; data is bind-mounted at `<dir>/data` (required) | `/storage/portainer`      |
| `PORTAINER_VERSION`      | Pinned Portainer image tag                             | `2.45.3`                     |
| `PORTAINER_HTTPS_PORT`   | Host port for the UI (container 9443), on 127.0.0.1    | `9443`                       |

## Deploy

From the repository root:

```bash
cp host/.env.example host/.env          # then edit
sudo ./create_volumes.sh host           # creates <DEFAULT_STORAGE_FOLDER>/data
docker network create cloudflared_shared-network   # skip if it already exists
cd host && docker compose up -d
```

Open `https://localhost:9443`. Portainer uses a self-signed certificate by default; HTTP is disabled. Create the admin user promptly after first start.

## Operate

Run inside `host/`:

```bash
docker compose ps
docker compose logs
docker compose restart
docker compose down
```

To upgrade, bump `PORTAINER_VERSION` in `.env` after reading the release notes, then `docker compose pull && docker compose up -d`.

See [`../SECURITY_HARDENING.md`](../SECURITY_HARDENING.md) for the hardening applied.
