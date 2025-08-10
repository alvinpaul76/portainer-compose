# Portainer Compose

This project provides a simple setup for running Portainer using Docker Compose.

## Files
- `docker-compose.yml`: Docker Compose configuration for Portainer.
- `create_volumes.sh`: Shell script to create required Docker volumes.

- `.env`: Environment variables for Docker Compose and Portainer configuration.

## Usage

1. **Create Docker Volumes**
   Run the following command to create the necessary volumes:
   ```bash
   ./create_volumes.sh
   ```

2. **Configure Environment Variables**
   Copy the example environment file and adjust values as needed:
   ```bash
   cp .env.example .env
   ```
   Edit `.env` to customize your setup if required.

2. **Start Portainer**
3. **Start Portainer**
   Use Docker Compose to start the services:
   ```bash
   docker-compose up -d
   ```

3. **Access Portainer**
4. **Access Portainer**
   Open your browser and go to `http://localhost:9000` to access the Portainer UI.

## Environment Variables

The `.env` file contains configuration for the Docker Compose setup:

- `SHARED_DOCKER_NETWORK`: Name of the shared Docker network (default: `cloudflared_shared-network`).
- `PORTAINER_PORT`: Port for the Portainer UI (default: `9000`).
- `PORTAINER_AGENT_PORT`: Port for the Portainer agent (default: `9001`).

## Requirements
- Docker
- Docker Compose

## License
MIT
