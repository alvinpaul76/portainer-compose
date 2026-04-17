# Deployment Modes

Portainer can be set up in different ways depending on your needs. This guide explains each mode and helps you choose the right one for your situation.

## Overview of Modes

This project supports three main deployment modes:

1. **Host Mode (Portainer Server)** - Run Portainer with a web interface on this computer
2. **Edge Agent Mode** - Run only the agent to be managed remotely by another Portainer server
3. **Swarm Mode** - Advanced setup for managing multiple computers as a cluster

## Mode 1: Host Mode (Portainer Server)

### What It Is

In Host Mode, Portainer runs on your computer with its own web interface. You access Portainer through a web browser to manage Docker containers on that same computer.

### When to Use This Mode

Choose Host Mode if:
- You only need to manage Docker on one computer
- You want a simple, straightforward setup
- You prefer to manage containers directly on the same machine
- You're new to Portainer and want to start simple

### How It Works

1. Portainer Server runs as a Docker container on your computer
2. It provides a web interface accessible through your browser
3. You manage containers, images, networks, and volumes through the web UI
4. All data is stored locally on your computer

### Setup Steps

```bash
# 1. Copy the host mode configuration
cp docker-compose-host.yml docker-compose.yml

# 2. Set up your environment file
cp .env.example .env

# 3. Create storage directories
sudo ./create_volumes.sh

# 4. Create the network
docker network create cloudflared_shared-network

# 5. Start Portainer
docker compose up -d

# 6. Access the web interface
# Open http://localhost:9000 in your browser
```

### Pros and Cons

**Pros:**
- Simple to set up and use
- Full control through a web interface
- No need for additional servers
- Perfect for single-computer setups
- Easy to learn and get started

**Cons:**
- Can only manage the computer it's running on (unless you add agents later)
- Web interface is only accessible from that computer (unless you configure remote access)
- All data stored on one computer (need backups)

### Typical Use Cases

- Home server managing personal projects
- Development machine for testing
- Small business with a single server
- Learning and experimenting with Docker

---

## Mode 2: Edge Agent Mode

### What It Is

In Edge Agent Mode, only a small "agent" program runs on your computer. This agent connects to a Portainer Server running elsewhere, allowing you to manage this computer remotely from that central server.

### When to Use This Mode

Choose Edge Agent Mode if:
- You already have a Portainer Server running elsewhere
- You want to manage multiple computers from one central location
- You're setting up a remote computer or server
- You're part of a team managing multiple machines

### How It Works

1. A lightweight agent runs on your computer
2. The agent connects to your Portainer Server (securely)
3. You manage this computer through the central Portainer web interface
4. The agent maintains a secure connection even if behind firewalls

### Setup Steps

#### Step 1: Get Edge ID and Edge Key from Your Portainer Server

1. Log in to your existing Portainer Server
2. Go to **Environments** in the left menu
3. Click **Add environment**
4. Select **Edge Agent**
5. Give it a name (e.g., "My Remote Computer")
6. Click **Create**
7. Copy the **Edge ID** and **Edge Key** that are displayed

#### Step 2: Configure Your Local Computer

```bash
# 1. Copy the edge agent configuration
cp docker-compose-edge-agent.yml docker-compose.yml

# 2. Set up your environment file
cp .env.example .env

# 3. Edit .env and add your Edge ID and Edge Key
nano .env
# Add these lines:
# PORTAINER_EDGE_ID=your-edge-id-here
# PORTAINER_EDGE_KEY=your-edge-key-here

# 4. Create storage directories
sudo ./create_volumes.sh

# 5. Create the network
docker network create cloudflared_shared-network

# 6. Start the agent
docker compose up -d
```

#### Step 3: Verify Connection

1. Go back to your Portainer Server web interface
2. You should see your new environment appear
3. Wait a few moments for the status to change to "Up"
4. You can now manage this computer from the central interface

### Pros and Cons

**Pros:**
- Manage multiple computers from one place
- Works through firewalls and NAT
- No need to open ports on the remote computer
- Centralized management and monitoring
- Secure connection with authentication

**Cons:**
- Requires an existing Portainer Server
- Slightly more complex initial setup
- Dependent on network connectivity to the server
- No local web interface on the agent computer

### Typical Use Cases

- Managing multiple servers in different locations
- Remote office computers managed from headquarters
- Cloud instances managed from an on-premises server
- IoT devices or edge computing nodes
- Team environments with centralized management

### Security Considerations

- Keep your Edge Key secret - treat it like a password
- Use HTTPS connections (keep `PORTAINER_EDGE_INSECURE_POLL=0`)
- Regenerate Edge Key if you suspect it's been compromised
- Don't commit Edge credentials to version control

---

## Mode 3: Swarm Mode (Advanced)

### What It Is

Swarm Mode is for advanced users who want to manage multiple computers as a single cluster. It uses Docker Swarm to distribute containers across multiple machines automatically.

### When to Use This Mode

Choose Swarm Mode if:
- You're managing 10+ computers
- You need automatic load balancing
- You want high availability and fault tolerance
- You're comfortable with Docker Swarm concepts
- You need advanced orchestration features

### Important Note

This project focuses on single-node setups. Swarm configuration requires additional setup not included in this project. You'll need to create additional configuration files based on Docker Swarm documentation.

### Basic Concept

- One or more manager nodes control the cluster
- Worker nodes run the actual containers
- Services are distributed automatically across the cluster
- If a node fails, containers are rescheduled elsewhere

### When to Consider This

- You're running a production environment with many users
- You need automatic scaling and load balancing
- You require high availability (no single point of failure)
- You have a dedicated operations team

### Recommendation

If you're new to Portainer, start with Host Mode. You can always add agents later or migrate to Swarm when you outgrow the simpler setup.

---

## Switching Between Modes

### From Host Mode to Edge Agent Mode

If you started with Host Mode but now want to connect to a central server:

```bash
# 1. Stop Portainer
docker compose down

# 2. Switch to edge agent configuration
cp docker-compose-edge-agent.yml docker-compose.yml

# 3. Update .env with your Edge ID and Edge Key
nano .env

# 4. Start the agent
docker compose up -d
```

**Note:** This will remove the local Portainer Server. Make sure you have access to the central Portainer Server before doing this.

### From Edge Agent Mode to Host Mode

If you want to convert an agent back to a standalone server:

```bash
# 1. Stop the agent
docker compose down

# 2. Switch to host configuration
cp docker-compose-host.yml docker-compose.yml

# 3. Remove Edge Agent settings from .env (optional)
nano .env
# You can remove or comment out PORTAINER_EDGE_ID and PORTAINER_EDGE_KEY

# 4. Start Portainer Server
docker compose up -d
```

---

## Comparison Table

| Feature | Host Mode | Edge Agent Mode | Swarm Mode |
|---------|-----------|-----------------|------------|
| **Complexity** | Simple | Medium | Complex |
| **Web Interface** | Yes (local) | No (on server) | Yes (on manager) |
| **Manage Local** | Yes | Via server | Via manager |
| **Manage Remote** | Add agents later | Yes | Yes |
| **Best For** | Single computer | Multi-computer | Large clusters |
| **Setup Time** | 5-10 minutes | 10-15 minutes | 30+ minutes |
| **Network** | Simple | Secure tunnel | Overlay network |
| **Firewall** | Need open port | Works through NAT | Need open ports |
| **Learning Curve** | Easy | Medium | Steep |

---

## Making Your Choice

### Choose Host Mode If:
- ✅ This is your first time using Portainer
- ✅ You only have one computer to manage
- ✅ You want the simplest possible setup
- ✅ You're running this at home or for personal projects

### Choose Edge Agent Mode If:
- ✅ You already have a Portainer Server
- ✅ You want to add this computer to existing management
- ✅ You're setting up a remote server
- ✅ You're part of a team managing multiple machines

### Choose Swarm Mode If:
- ✅ You're managing many computers (10+)
- ✅ You need advanced orchestration features
- ✅ You have Docker Swarm experience
- ✅ You need high availability and auto-scaling

---

## Still Unsure?

If you're not sure which mode to choose:

1. **Start with Host Mode** - It's the simplest and you can always change later
2. **Read the Installation Guide** - It walks through Host Mode setup step by step
3. **Check the FAQ** - Common questions about choosing modes are answered there
4. **Experiment** - You can try different modes in test environments before committing

Remember: You can always switch modes later. The important thing is to get started with something that works for your current needs.

---

## Need More Help?

- [Installation Guide](installation.md) - Step-by-step setup instructions
- [Configuration Guide](configuration.md) - How to customize settings
- [Getting Started](getting-started.md) - Introduction to Portainer
- [FAQ](faq.md) - Common questions and answers
