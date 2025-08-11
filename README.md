# Portainer Compose

This repository provides multiple Compose variants so you can choose the desired deployment role for this machine:

1. `docker-compose-host.yml` – Portainer Server (UI + management backend) running locally to manage this host (and optionally others you add later).
2. `docker-compose-edge-agent.yml` – Portainer Edge Agent only (this node is managed remotely by an existing Portainer instance – no local UI).
3. (Legacy / Swarm) `docker-compose-agent.yml` – Agent service definition for Swarm global mode when pairing with a separately deployed server stack.

HOW TO CHOOSE:
* If this machine SHOULD HOST the Portainer UI: copy `docker-compose-host.yml` to `docker-compose.yml`.
* If this machine SHOULD ONLY BE AN EDGE AGENT (managed remotely): copy `docker-compose-edge-agent.yml` to `docker-compose.yml`.
* For a Swarm with multiple nodes where this node runs the server AND you also want agents globally, deploy the server with the host file (renamed to `docker-compose.yml`) and then deploy the Swarm agent stack separately (see Multi-Node section).

Copy command examples:
```bash
# Host (Portainer Server) mode
cp docker-compose-host.yml docker-compose.yml

# Edge Agent only mode
cp docker-compose-edge-agent.yml docker-compose.yml
```

After copying, adjust `.env` (especially Edge ID / Edge Key for edge mode) before `docker compose up -d`.

> NOTE: The currently committed `docker-compose.yml` in this branch is configured for **Edge Agent mode** (it contains only the `agent` service). If you intend to run the full Portainer Server UI on this node, replace it by copying `docker-compose-host.yml` over it.

---
## Files
- `docker-compose-host.yml` – Template for running the Portainer Server locally.
- `docker-compose-edge-agent.yml` – Template for running ONLY the Edge Agent on this node.
- `docker-compose-agent.yml` – (Swarm) Global agent service definition (used with `docker stack deploy`).
- `docker-compose.yml` – Active file Docker Compose will use (create by copying one of the above).
- `create_volumes.sh` – Creates the bind-mounted data directory (`/storage/portainer/data`). Requires root (`sudo`).
- `.env` / `.env.example` – Centralized configuration variables.

---
## Environment Variables

Defined in `.env` (copy from `.env.example` first):

| Variable | Purpose | Typical Value |
|----------|---------|---------------|
| `SHARED_DOCKER_NETWORK` | External network both services join | `cloudflared_shared-network` |
| `PORTAINER_PORT` | Host port exposing Portainer UI (maps container 9000) | `9000` |
| `PORTAINER_AGENT_PORT` | Host port exposing Agent (maps container 9001) | `9001` |

You may change the host bind directory in the compose files if `/storage/portainer/data` is not suitable.

### Additional Environment Variables (Edge Agent Mode)
These are only required (or meaningful) when you deploy using `docker-compose-edge-agent.yml` (Edge Agent only mode):

| Variable | Required | Purpose | Notes |
|----------|----------|---------|-------|
| `EDGE` | Yes | Enables Edge agent features | Always set to `1` for Edge mode. |
| `EDGE_ID` | Yes | Unique identifier for this Edge endpoint | Provided by your remote Portainer instance when adding an Edge environment. |
| `EDGE_KEY` | Yes | Auth + configuration bootstrap string (contains URL + token) | Copy EXACTLY as generated; treat as secret. Regenerate if leaked. |
| `EDGE_INSECURE_POLL` | Optional | Allow insecure (non-TLS) polling to the Edge endpoint | Set to `1` only if your Edge server runs without TLS (development). Remove or set `0` for production HTTPS. |
| `LOG_LEVEL` | Optional | Adjust agent logging verbosity | Common values: `INFO`, `DEBUG` (default in template set to `DEBUG`). Use `INFO` in production. |

Edge variables lifecycle:
1. In your remote Portainer UI: Add Environment → Edge Agent → copy generated `EDGE_ID` & `EDGE_KEY`.
2. Paste into `.env` (or directly into compose file if preferred, but `.env` is cleaner).
3. Start the agent: `docker compose up -d`.
4. In the Portainer UI the environment should appear as "Up" once the reverse tunnel is established (may take a few seconds).

Security tips:
* Rotate (regenerate) the Edge Key if you suspect compromise.
* Avoid committing real `EDGE_ID` / `EDGE_KEY` values—use placeholders in public repos.
* Prefer HTTPS termination (so you can omit `EDGE_INSECURE_POLL`).

---
## Quick Start (Single Host – Portainer Server Mode)

Use this if you only need to manage the local Docker engine.

```bash
# 1. Clone repo & enter directory
# git clone <this-repo> && cd portainer-compose

# 2. Pick mode (host server vs edge agent) and copy template
# Host (Server) mode:
cp docker-compose-host.yml docker-compose.yml
# OR Edge Agent only mode:
# cp docker-compose-edge-agent.yml docker-compose.yml

# 3. Prepare environment file
cp .env.example .env

# 4. Create external bridge network (if it does not already exist)
docker network create ${SHARED_DOCKER_NETWORK}

# 5. (Server mode only) Create data directory (runs as root because path is under /storage)
sudo ./create_volumes.sh

# 6. Start (Server or Edge Agent depending on what you copied)
docker compose up -d

# 7. (Server mode) Access UI
open http://localhost:${PORTAINER_PORT}

# Edge Agent mode: No local UI. In your remote Portainer instance, add/register the Edge environment using the Edge ID / Edge Key you placed in `.env`.
```

Cleanup (optional):
```bash
docker compose down
```

---
## Multi-Node / Swarm Deployment (Server + Agent)

Use Docker Swarm when you want Portainer Server to manage multiple nodes securely via the Agent.

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
cp .env.example .env
sudo ./create_volumes.sh
```

### 4. Deploy Portainer Server as a Stack
```bash
docker stack deploy -c docker-compose.yml portainer
```

### 5. Deploy Portainer Agent Stack
The agent compose defines a global service (one agent per node).
```bash
docker stack deploy -c docker-compose-agent.yml portainer-agent
```

### 6. Add Worker Nodes
Run the printed `docker swarm join ...` command on each additional node. No need to manually create the external network or copy the stacks there; Swarm handles scheduling.

### 7. Access the UI
Open:
```
http://<manager-host>:${PORTAINER_PORT}
```
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
docker stack deploy -c docker-compose.yml portainer
docker stack deploy -c docker-compose-agent.yml portainer-agent
```

### 10. Removal
```bash
docker stack rm portainer-agent
docker stack rm portainer
docker network rm ${SHARED_DOCKER_NETWORK}
```

---
## Notes & Tips
- The `deploy:` section in `docker-compose-agent.yml` only works with `docker stack deploy` (Swarm). `docker compose up` ignores it.
- If you later enable HTTPS, expose port 9443 by adding a mapping (`9443:9443`) to the server service and access `https://host:9443`.
- Ensure `/storage/portainer/data` resides on persistent storage (e.g., mounted volume, RAID, etc.).
- Adjust permissions more restrictively than `777` if you have stricter security requirements; the script uses wide permissions for simplicity.

---
## Troubleshooting
- Portainer not reachable: Confirm container running (`docker ps`) and no firewall blocking `${PORTAINER_PORT}`.
- Agent shows offline: Ensure overlay network exists and the agent container can resolve the server via network.
- Volume path errors: Create or adjust the host directory path in the compose file, then rerun `create_volumes.sh` with updated logic (or manually mkdir/chown).

---
## License
MIT
