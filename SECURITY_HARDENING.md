# Security Hardening – Portainer Compose

## Overview

This document summarizes the security hardening changes applied to the Portainer Compose deployment.

---

## 1. Image Pinning

Images currently use `:latest` for automatic updates.

| Service           | Current Tag                      | Recommended (pinned)            |
| ----------------- | -------------------------------- | ------------------------------- |
| Portainer Server  | `portainer/portainer-ce:latest`  | `portainer/portainer-ce:2.39.6` |
| Portainer Agent   | `portainer/agent:latest`         | `portainer/agent:2.39.6`        |

**Recommendation:** For stricter supply-chain control, pin to a specific version and update deliberately after reviewing release notes. The initial hardening pinned images to `2.39.6` but this was reverted to `:latest` in favor of automatic updates.

---

## 2. Localhost-Only Port Binding

**Before:** Ports bound to `0.0.0.0` (all interfaces).
**After:** All ports bound to `127.0.0.1` (localhost only).

| Service | Port Mapping                       |
| ------- | ---------------------------------- |
| Server  | `127.0.0.1:${PORTAINER_PORT}:9000` |
| Server  | `127.0.0.1:${PORTAINER_HTTPS_PORT}:9443` |
| Agent   | `127.0.0.1:${PORTAINER_AGENT_PORT}:9001` |

**Why:** Services are not directly exposed to external interfaces. Use a reverse proxy (e.g., Cloudflare Tunnel via the `shared-network`) for external access with TLS.

---

## 3. HTTPS Port Added

**Before:** Only HTTP port `9000` exposed.
**After:** HTTPS port `9443` also exposed via new env var `PORTAINER_HTTPS_PORT=9443`.

**Why:** Portainer supports native HTTPS on port `9443` with a self-signed certificate. Prefer `https://localhost:9443` for direct access. Configure a custom certificate in the Portainer UI for production.

---

## 4. Container Isolation

### `no-new-privileges: true`
Prevents processes inside the container from gaining additional capabilities via setuid binaries.

### `cap_drop: ALL`
Drops all Linux capabilities. Portainer communicates with Docker via the socket and does not need direct kernel capabilities.

### `read_only: true`
Makes the container filesystem read-only. Writable areas are provided via `tmpfs` mounts.

### `tmpfs` Mounts
- **Server:** `/tmp`
- **Agent:** `/tmp` (agent `/data` uses a named volume for persistence across restarts)

### `pids_limit`
Restricts the number of processes the container can spawn (DoS mitigation).
- Server: `200`
- Agent: `100`

---

## 5. Resource Limits

Prevents a single container from exhausting host resources.

| Resource         | Server  | Agent   |
| ---------------- | ------- | ------- |
| `mem_limit`      | 512 MB  | 256 MB  |
| `mem_reservation`| 256 MB  | 128 MB  |
| `cpus`           | 1.0     | 0.5     |
| `pids_limit`     | 200     | 100     |

---

## 6. Healthchecks

Both server and agent include healthchecks so Docker can detect and restart unhealthy containers.

| Service | Check                                              | Interval | Timeout | Retries | Start Period |
| ------- | -------------------------------------------------- | -------- | ------- | ------- | ------------ |
| Server  | `wget --spider -q http://localhost:9000`           | 30s      | 5s      | 3       | 30s          |
| Agent   | `wget --spider -q http://localhost:9001`           | 30s      | 5s      | 3       | 15s          |

---

## 7. Data Directory Permissions

**Before:** `create_volumes.sh` set `chmod -R 777` (world-writable).
**After:** `chmod -R 750` (owner rwx, group rx, no world access).

**Why:** Prevents unauthorized users from reading or modifying Portainer data.

---

## 8. Log Level Hardened

**Before:** `PORTAINER_LOG_LEVEL=DEBUG`
**After:** `PORTAINER_LOG_LEVEL=INFO`

**Why:** `DEBUG` level may log sensitive request data. `INFO` is appropriate for production.

---

## 9. Files Modified

| File                              | Changes                                                    |
| --------------------------------- | ---------------------------------------------------------- |
| `docker-compose-host.yml`         | Image pin, HTTPS port, localhost binding, isolation, resource limits, healthcheck |
| `docker-compose-edge-agent.yml`   | Image pin, localhost binding, isolation, resource limits, healthcheck, `/data` named volume |
| `create_volumes.sh`               | `chmod 777` → `chmod 750`                                  |
| `.env.example`                    | Added `PORTAINER_HTTPS_PORT`, `LOG_LEVEL` → `INFO`         |
| `README.md`                       | Added Security Hardening section, updated env var table, updated notes |

---

## 10. Remaining Risk: Docker Socket

Portainer requires access to `/var/run/docker.sock` to manage Docker. This grants full Docker daemon access (equivalent to root on the host).

**Mitigations:**
- Keep Portainer behind a reverse proxy with authentication
- Restrict network access to the host
- Monitor audit logs
- For higher security requirements, consider [socket proxies](https://github.com/Tecnativa/docker-socket-proxy) that filter Docker API calls

---

## 11. Bug Fix: Agent `/data` Read-Only Filesystem

After applying `read_only: true`, the Portainer Edge Agent crashed with:

```
FTL unable to associate Edge key | error="mkdir /data: read-only file system"
```

**Fix:** The agent's `/data` directory is mounted as a named volume (`agent_data`) so the agent can write its Edge key and association data to a persistent writable directory while the rest of the filesystem remains read-only. This survives container restarts, unlike a `tmpfs` mount which would lose data on every restart.
