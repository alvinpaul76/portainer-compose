# Portainer Compose

This repository provides Compose variants so you can choose the deployment role for this machine:

1. `host/` – Portainer Server (UI + management backend) running locally to manage this host (and optionally others you add later).
2. `nginx/` – Portainer Server behind an nginx reverse proxy (nginx `1.31.3-alpine`) on a private network, exposing the UI on `127.0.0.1:8080` for Cloudflare Tunnel or similar. This is the more locked-down server variant.
3. `edge-agent/` – Portainer Edge Agent only (this node is managed remotely by an existing Portainer instance – no local UI).

Each folder is an independent deployment with its own `docker-compose.yml`, `.env.example` and `README.md`. Copy `.env.example` to `.env` inside the folder you pick, then run `docker compose up -d` there. `edge-agent/` additionally needs `.env.agent` (Infisical credentials); see its README.

NOTE ABOUT SWARM: A Swarm "global" agent compose file (`docker-compose-agent.yml`) is referenced in some Portainer docs but is NOT included in this repo right now. If you intend to run a Swarm with a global agent service, you can add that file later (see the Swarm section for guidance). Until then, this repo focuses on single‑node server mode or Edge Agent mode.

HOW TO CHOOSE:

- Host (Server) mode (you want the UI here): `host/`.
- Server with nginx proxy (UI behind reverse proxy): `nginx/`.
- Edge Agent only mode (UI is elsewhere): `edge-agent/`.
- Swarm with global agents: deploy the server using `docker stack deploy` with a server compose, then add a Swarm agent stack file (not presently in repo) defining a global agent service.

Example:

```bash
cp host/.env.example host/.env           # or nginx / edge-agent; then edit .env
sudo ./create_volumes.sh host            # run for every variant (same name as above)
cd host && docker compose up -d
```

The three variants all use the same container names, so run only one per host.

---

## Variant docs

Each variant documents its own environment variables, deploy steps and operations:

| Variant        | Guide                                    |
| -------------- | ---------------------------------------- |
| `host/`        | [host/README.md](host/README.md)         |
| `nginx/`       | [nginx/README.md](nginx/README.md)       |
| `edge-agent/`  | [edge-agent/README.md](edge-agent/README.md) |

## Repository layout

- `host/`, `nginx/`, `edge-agent/` – one deployment each: `docker-compose.yml`, `.env.example`, `README.md`. `nginx/` also has `nginx.conf`; `edge-agent/` also has `.env.agent.example` and `infisical/` (sidecar config and secret template).
- `.infisical.yaml` – Infisical CLI project link (project ID only, no secrets).
- `.scratch/` – Per-change notes (resolved issue write-ups); not needed for deployment.
- `create_volumes.sh` – Creates the bind-mounted data directory for a variant: `sudo ./create_volumes.sh <host|nginx|edge-agent>`. Requires root.
- `SECURITY_HARDENING.md` – Security measures applied to the compose files, and remaining risks (notably Docker socket access).
- (Not included) `docker-compose-agent.yml` – Would define a Swarm global agent service if you add Swarm later.

## Security

All variants pin image versions (via required `*_IMAGE` variables in `.env`), bind published ports to `127.0.0.1`, drop all capabilities, use read-only root filesystems for the Portainer and nginx containers, and set resource limits. The `edge-agent/` variant keeps its Edge ID/Key in Infisical rather than on disk. Portainer needs the Docker socket, which grants full daemon access. See [SECURITY_HARDENING.md](SECURITY_HARDENING.md).

---

## Multi-Node / Swarm Deployment (Server + Agent)

Use Docker Swarm when you want Portainer Server to manage multiple nodes securely via the Agent. A Swarm agent stack file isn't bundled here; you can create one modeled on Portainer's official docs if needed.

> **Warning:** Only `host/` is a sensible Swarm candidate. `edge-agent/` relies on `depends_on` conditions and one-shot services that `docker stack deploy` does not support, and `nginx/` uses `internal` networks and `container_name`. The security hardening directives in the compose files (`read_only`, `tmpfs`, `cap_drop`, `security_opt`, `mem_limit`, `cpus`, `pids_limit`) are **Compose v2 options** that `docker stack deploy` silently ignores. If you deploy via Swarm, these protections will NOT be applied. To harden Swarm deployments, use `deploy.resources.limits` for resource constraints and apply `security_opt`/`cap_drop` via Swarm service configs or a custom image.

### 1. Initialize Swarm (on manager node)

```bash
docker swarm init
```

If you already have a swarm, skip this. Capture the worker join token if you will add more nodes:

```bash
docker swarm join-token worker
```

### 2. Create External Overlay Network

The compose files expect an externally created network named in `SHARED_DOCKER_NETWORK`.

```bash
docker network create \
   --driver overlay \
   --attachable \
   ${SHARED_DOCKER_NETWORK}
```

Why attachable? It allows non-swarm (standalone) containers or troubleshooting shells to join.

### 3. Prepare Environment & Data

```bash
cp host/.env.example host/.env
sudo ./create_volumes.sh host
```

### 4. Deploy Portainer Server as a Stack

```bash
docker stack deploy -c host/docker-compose.yml portainer
```

### 5. Deploy Portainer Agent Stack (Add Your Own File)

Create a `docker-compose-agent.yml` (not included) similar to:

```yaml
version: "3.8"
services:
  agent:
    image: portainer/agent:latest
    networks:
      - portainer_agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]
networks:
  portainer_agent:
    driver: overlay
    attachable: true
```

Then deploy it:

```bash
docker stack deploy -c docker-compose-agent.yml portainer-agent
```

### 6. Add Worker Nodes

Run the printed `docker swarm join ...` command on each additional node. No need to manually create the external network or copy the stacks there; Swarm handles scheduling.

### 7. Access the UI

Open:

```
https://<manager-host>:9443
```

Swarm stacks do not read `.env` automatically; export the variables or use `docker compose config` to render the file first.

On first login, create the admin user, then add the managed environments (the local swarm + agents should auto-register or appear for association).

### 8. Verify

```bash
docker stack ls
docker stack services portainer
docker stack services portainer-agent
```

### 9. Upgrading

Pull new images and redeploy:

```bash
# Bump PORTAINER_IMAGE (and your agent image) in .env first, then:
docker pull "$PORTAINER_IMAGE"
docker pull portainer/agent:<same-version>
docker stack deploy -c host/docker-compose.yml portainer
docker stack deploy -c docker-compose-agent.yml portainer-agent
```

### 10. Removal

```bash
docker stack rm portainer-agent
docker stack rm portainer
docker network rm "$SHARED_DOCKER_NETWORK"
```

---

## Notes & Tips

- The `deploy:` section in a Swarm agent file only works with `docker stack deploy`; `docker compose up` ignores it.
- Keep the data directory (`DEFAULT_STORAGE_FOLDER`) on persistent storage. `create_volumes.sh` sets it to `750`.

---

## Troubleshooting

Variant-specific issues are covered in each variant's README. General checks:

- Portainer not reachable: confirm the container is running (`docker ps`) and nothing blocks the published port (`9443` for `host/`, `NGINX_PORT` for `nginx/`).
- Volume path errors: check `DEFAULT_STORAGE_FOLDER` in the variant's `.env` and rerun `create_volumes.sh` (or mkdir/chown manually).

---

## License

MIT License - see [LICENSE](LICENSE) for details.

## Additional Resources

- [Official Portainer Documentation](https://docs.portainer.io)
- [Portainer Forums](https://forums.portainer.io)
- [Docker Documentation](https://docs.docker.com)
