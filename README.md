# Portainer Compose

This repository provides two Compose files:

1. `docker-compose.yml` – Runs the Portainer Server (UI + management backend).
2. `docker-compose-agent.yml` – Runs the Portainer Agent (intended for Docker Swarm / multi-node setups).

Use ONLY the server compose file for a single-host setup. Use BOTH (as stacks) when you want to manage multiple swarm nodes via the Portainer Agent.

---
## Files
- `docker-compose.yml` – Portainer Server definition.
- `docker-compose-agent.yml` – Portainer Agent (global service) for Swarm.
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

---
## Quick Start (Single Host – No Swarm, Just Portainer Server)

Use this if you only need to manage the local Docker engine.

```bash
# 1. Clone repo & enter directory
# git clone <this-repo> && cd portainer-compose

# 2. Prepare environment file
cp .env.example .env

# 3. Create external bridge network (if it does not already exist)
docker network create ${SHARED_DOCKER_NETWORK}

# 4. Create data directory (runs as root because path is under /storage)
sudo ./create_volumes.sh

# 5. Start Portainer Server
docker compose up -d   # or: docker-compose up -d

# 6. Access UI
open http://localhost:${PORTAINER_PORT}
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
