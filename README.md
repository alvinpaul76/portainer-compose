# Portainer Compose

This repository provides Compose variants so you can choose the deployment role for this machine:

1. `host/` – Portainer Server (UI + management backend) running locally to manage this host (and optionally others you add later).
2. `nginx/` – Portainer Server behind an nginx reverse proxy (nginx `1.31.3-alpine`) on a private network, exposing the UI on `127.0.0.1:8080` for Cloudflare Tunnel or similar. This is the more locked-down server variant.
3. `edge-agent/` – Portainer Edge Agent only (this node is managed remotely by an existing Portainer instance – no local UI).

Each folder is an independent deployment with its own `docker-compose.yml` and `.env.example`. Copy `.env.example` to `.env` inside the folder you pick, then run `docker compose up -d` there.

NOTE ABOUT SWARM: A Swarm "global" agent compose file (`docker-compose-agent.yml`) is referenced in some Portainer docs but is NOT included in this repo right now. If you intend to run a Swarm with a global agent service, you can add that file later (see the Swarm section for guidance). Until then, this repo focuses on single‑node server mode or Edge Agent mode.

HOW TO CHOOSE:

- Host (Server) mode (you want the UI here): `host/`.
- Server with nginx proxy (UI behind reverse proxy): `nginx/`.
- Edge Agent only mode (UI is elsewhere): `edge-agent/`.
- Swarm with global agents: deploy the server using `docker stack deploy` with a server compose, then add a Swarm agent stack file (not presently in repo) defining a global agent service.

Example:

```bash
cd host                      # or nginx / edge-agent
cp .env.example .env         # then edit .env
cd .. && sudo ./create_volumes.sh host   # not needed for edge-agent
cd host && docker compose up -d
```

The three variants all use the same container names, so run only one per host.

---

## Files

- `host/` – `docker-compose.yml` + `.env.example` for the Portainer Server.
- `nginx/` – `docker-compose.yml`, `.env.example` and `nginx.conf` for Portainer Server behind nginx.
- `edge-agent/` – `docker-compose.yml` + `.env.example` for ONLY the Edge Agent on this node.
- `create_volumes.sh` – Creates the bind-mounted data directory for a variant: `sudo ./create_volumes.sh <host|nginx|edge-agent>`. Requires root.
- `SECURITY_HARDENING.md` – Detailed documentation of all security hardening measures applied.
- (Not included) `docker-compose-agent.yml` – Would define a Swarm global agent service if you add Swarm later.

---

## Environment Variables

Defined in `<variant>/.env` (copy from that folder's `.env.example` first; each variant only uses the variables it lists):

| Variable                | Purpose                                               | Typical Value                |
| ----------------------- | ----------------------------------------------------- | ---------------------------- |
| `SHARED_DOCKER_NETWORK` | External network both services join                   | `cloudflared_shared-network` |
| `PORTAINER_VERSION`     | Portainer server/agent image tag (pinned)             | `2.45.3`                     |
| `PORTAINER_HTTPS_PORT`  | Host port exposing Portainer UI HTTPS (container 9443)| `9443`                       |
| `NGINX_PORT`            | Host port for the nginx variant (127.0.0.1 only)      | `8080`                       |

Change `DEFAULT_STORAGE_FOLDER` in `.env` if `/storage/portainer/data` is not suitable.

### Additional Environment Variables (Edge Agent Mode)

These are only required (or meaningful) when you deploy using `edge-agent/` (Edge Agent only mode). Names below match `edge-agent/.env.example`:

| Variable                       | Required | Purpose                                                      | Notes                                                                                              |
| ------------------------------ | -------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------- |
| (hard-coded) `EDGE=1`          | Yes      | Enables Edge agent features                                  | Set inside compose; you do NOT need it in `.env`.                                                  |
| `PORTAINER_EDGE_ID`            | Yes      | Unique identifier for this Edge endpoint                     | Provided by your remote Portainer instance when adding an Edge environment.                        |
| `PORTAINER_EDGE_KEY`           | Yes      | Auth + configuration bootstrap string (contains URL + token) | Copy EXACTLY as generated; treat as secret. Regenerate if leaked.                                  |
| `PORTAINER_EDGE_INSECURE_POLL` | Optional | Allow insecure (non-TLS) polling to the Edge endpoint        | Set to `1` only if your Edge server runs without TLS (development). Keep `0` for production HTTPS. |
| `PORTAINER_LOG_LEVEL`          | Optional | Adjust agent logging verbosity                               | Common: `INFO`, `DEBUG`. Use `INFO` in production.                                                 |

> **Security note:** `PORTAINER_LOG_LEVEL` defaults to `INFO`. Avoid `DEBUG` in production as it may log sensitive request data.

Edge variables lifecycle:

1. In your remote Portainer UI: Add Environment → Edge Agent → copy generated `EDGE_ID` & `EDGE_KEY`.
2. Paste into `.env` as `PORTAINER_EDGE_ID` / `PORTAINER_EDGE_KEY` (or directly into compose file if preferred, but `.env` is cleaner).
3. Start the agent: `docker compose up -d`.
4. In the Portainer UI the environment should appear as "Up" once the reverse tunnel is established (may take a few seconds).

Security tips:

- Rotate (regenerate) the Edge Key if you suspect compromise.
- Avoid committing real `PORTAINER_EDGE_ID` / `PORTAINER_EDGE_KEY` values—use placeholders in public repos.
- Prefer HTTPS termination (so you can omit `PORTAINER_EDGE_INSECURE_POLL`).
- Use `INFO` log level in production (never `DEBUG`).

---

## Security Hardening

The compose files in this repo have been hardened with the following measures:

### Image Pinning
- Images are pinned via `PORTAINER_VERSION` (default `2.45.3`) instead of `:latest`. Bump it deliberately after reviewing release notes.

### Network Binding
- All host port mappings bind to `127.0.0.1` (localhost only) so services are not exposed to external interfaces.
- Use a reverse proxy (e.g., Cloudflare Tunnel via the `shared-network`) to expose services externally with TLS.

### Container Isolation
- **`no-new-privileges:true`** – prevents processes inside the container from gaining additional capabilities via setuid binaries.
- **`cap_drop: ALL`** – drops all Linux capabilities; Portainer communicates with Docker via the socket and does not need direct kernel capabilities.
- **`read_only: true`** – makes the container filesystem read-only; writable areas use `tmpfs` mounts (`/tmp` for both server and agent). The agent's `/data` uses a named volume (`agent_data`) for persistence across restarts.
- **`pids_limit`** – restricts the number of processes the container can spawn (DoS mitigation).
- **Note:** The Edge Agent requires `/data` as a named volume (`agent_data`) because it writes Edge key and association data there at startup. Without it, the agent crashes with `mkdir /data: read-only file system`.

### Resource Limits
- Memory and CPU limits prevent a single container from exhausting host resources.
- Server: 512 MB memory, 1 CPU. Agent: 256 MB memory, 0.5 CPU.

### Healthchecks
- Only the nginx proxy has a healthcheck. The Portainer server and agent images are scratch-based (no shell, `wget` or `curl`), so a CMD-based check always reports `unhealthy`.

### Data Directory Permissions
- `create_volumes.sh` sets `chmod 750` (owner rwx, group rx, no world access) instead of the previous `777`.

### HTTPS
- The host variant publishes only `9443` (HTTPS); plain HTTP is disabled by default in Portainer. The nginx variant enables HTTP on a private internal network that only nginx can reach.
- Portainer generates a self-signed certificate by default; configure your own certificate in the Portainer UI for production.

### Remaining Risk: Docker Socket
- Portainer requires access to `/var/run/docker.sock` to manage Docker. This grants full Docker daemon access.
- Mitigation: keep Portainer behind a reverse proxy with authentication, restrict network access, and monitor audit logs.
- For higher security requirements, consider [socket proxies](https://github.com/Tecnativa/docker-socket-proxy) that filter Docker API calls.

---

## Quick Start (Single Host – Portainer Server Mode)

Use this if you only need to manage the local Docker engine.

```bash
# 1. Set up your environment file
cp host/.env.example host/.env

# 2. Create storage directories
sudo ./create_volumes.sh host

# 3. Create the Docker network
docker network create cloudflared_shared-network

# 4. Start Portainer (from inside the variant folder)
cd host && docker compose up -d

# 5. (Server mode) Access UI
# HTTPS:  https://localhost:9443   (host variant; HTTP is disabled by default in Portainer)
# nginx variant: http://localhost:8080
# (Replace the ports with PORTAINER_HTTPS_PORT / NGINX_PORT if changed in .env)

# Edge Agent mode (edge-agent/): No local UI. In your remote Portainer instance, add/register the Edge environment using the Edge ID / Edge Key you placed in `edge-agent/.env`.
```

Cleanup (optional). Run these inside the variant folder (`host/`, `nginx/` or `edge-agent/`):

```bash
# Check if Portainer is running
docker compose ps

# View Portainer logs
docker compose logs

# Restart Portainer
docker compose restart

# Stop Portainer
docker compose down
```

---

## Multi-Node / Swarm Deployment (Server + Agent)

Use Docker Swarm when you want Portainer Server to manage multiple nodes securely via the Agent. A Swarm agent stack file isn't bundled here; you can create one modeled on Portainer's official docs if needed.

> **Warning:** The security hardening directives in the compose files (`read_only`, `tmpfs`, `cap_drop`, `security_opt`, `mem_limit`, `cpus`, `pids_limit`) are **Compose v2 options** that `docker stack deploy` silently ignores. If you deploy via Swarm, these protections will NOT be applied. To harden Swarm deployments, use `deploy.resources.limits` for resource constraints and apply `security_opt`/`cap_drop` via Swarm service configs or a custom image.

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
http://<manager-host>:9000
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
docker pull portainer/portainer-ce:latest
docker pull portainer/agent:latest
docker stack deploy -c host/docker-compose.yml portainer
docker stack deploy -c docker-compose-agent.yml portainer-agent
```

### 10. Removal

```bash
docker stack rm portainer-agent
docker stack rm portainer
docker network rm cloudflared_shared-network
```

---

## Notes & Tips

- The `deploy:` section in `docker-compose-agent.yml` only works with `docker stack deploy` (Swarm). `docker compose up` ignores it.
- HTTPS is already enabled via port `9443` (mapped to `127.0.0.1:9443` by default). Access `https://localhost:9443` for the secure UI.
- Ensure `/storage/portainer/data` resides on persistent storage (e.g., mounted volume, RAID, etc.).
- Data directory permissions are set to `750` by `create_volumes.sh` (owner rwx, group rx, no world access).

---

## Troubleshooting

- Portainer not reachable: Confirm container running (`docker ps`) and no firewall blocking port `9000` (HTTP) or `9443` (HTTPS).
- Agent shows offline: Ensure overlay network exists and the agent container can resolve the server via network.
- Agent crash with `mkdir /data: read-only file system`: The `read_only: true` setting requires `/data` to be a writable volume. Verify `agent_data:/data` is present in the compose file's `volumes` section.
- Volume path errors: Create or adjust the host directory path in the compose file, then rerun `create_volumes.sh` with updated logic (or manually mkdir/chown).

---

## License

MIT License - See LICENSE file for details

## Additional Resources

- [Official Portainer Documentation](https://docs.portainer.io)
- [Portainer Forums](https://forums.portainer.io)
- [Docker Documentation](https://docs.docker.com)

---

**Ready to get started?** Follow the [Quick Start](#quick-start-single-host--portainer-server-mode) section above.
