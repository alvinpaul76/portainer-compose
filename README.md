# Portainer Compose

A simple, user-friendly way to set up Portainer - a web-based tool for managing Docker containers through an easy-to-use interface.

## What is Portainer?

Portainer is a graphical interface that makes managing Docker containers simple. Instead of remembering complex commands, you can click buttons and fill in forms to manage your containers, images, networks, and volumes.

This project provides ready-to-use configuration files that handle the technical setup for you, so you can focus on using Portainer rather than configuring it.

## Quick Start

**New to Portainer?** Start with our [Getting Started Guide](docs/getting-started.md) to learn the basics.

**Ready to install?** Follow the [Installation Guide](docs/installation.md) for step-by-step instructions.

**Not sure which mode to use?** Read about [Deployment Modes](docs/deployment-modes.md) to choose the right setup for your needs.

## Documentation

All documentation is organized in the `docs/` folder for easy maintenance:

### Essential Reading

- **[Getting Started](docs/getting-started.md)** - Introduction to Portainer and this project. Perfect for new users.
- **[Installation Guide](docs/installation.md)** - Step-by-step instructions to set up Portainer on your computer.
- **[Deployment Modes](docs/deployment-modes.md)** - Learn about the different ways to use Portainer and choose the right one.

### Configuration & Customization

- **[Configuration Guide](docs/configuration.md)** - How to customize Portainer settings to fit your needs.

### Help & Support

- **[Troubleshooting Guide](docs/troubleshooting.md)** - Solutions to common problems and issues.
- **[FAQ](docs/faq.md)** - Frequently asked questions and quick answers.

## What You'll Need

Before you begin, make sure you have:
- **Docker installed** on your computer or server
- **Basic computer skills** - you should be comfortable using a terminal or command prompt
- **Administrator access** (sudo or root privileges) - needed to create folders and set permissions

## Choosing Your Setup Mode

This project supports three main ways to use Portainer:

### 1. Single Computer Setup (Host Mode)
**Best for:** Managing Docker on just one computer

Run Portainer with a web interface directly on your computer. Simple, straightforward, perfect for personal projects or single-server setups.

**Get started:** [Installation Guide](docs/installation.md)

### 2. Remote Agent Setup (Edge Agent Mode)
**Best for:** Managing multiple computers from one central location

Connect this computer to an existing Portainer server elsewhere. Ideal for remote servers, multiple locations, or team environments.

**Get started:** [Deployment Modes](docs/deployment-modes.md#mode-2-edge-agent-mode)

### 3. Multi-Computer Cluster (Swarm Mode)
**Best for:** Advanced users managing many computers as a group

For experienced users who need advanced orchestration, load balancing, and high availability across multiple machines.

**Learn more:** [Deployment Modes](docs/deployment-modes.md#mode-3-swarm-mode-advanced)

## Project Files

This project includes several configuration files:

- `docker-compose-host.yml` - Template for running Portainer Server with web interface
- `docker-compose-edge-agent.yml` - Template for running only the Edge Agent
- `docker-compose.yml` - The active file (copy one of the templates to this name)
- `.env.example` - Example configuration file with all available settings
- `create_volumes.sh` - Script to create storage directories (requires sudo)

## Quick Installation Summary

For the most common setup (single computer with web interface):

```bash
# 1. Copy the host mode configuration
cp docker-compose-host.yml docker-compose.yml

# 2. Set up your environment file
cp .env.example .env

# 3. Create storage directories
sudo ./create_volumes.sh

# 4. Create the Docker network
docker network create cloudflared_shared-network

# 5. Start Portainer
docker compose up -d

# 6. Access the web interface
# Open http://localhost:9000 in your browser
```

For detailed instructions with explanations, see the [Installation Guide](docs/installation.md).

## Common Commands

```bash
# Check if Portainer is running
docker compose ps

# View Portainer logs
docker compose logs

# Restart Portainer
docker compose restart

# Stop Portainer
docker compose down

# Start Portainer
docker compose up -d

# Update Portainer to latest version
docker compose pull
docker compose up -d
```

## Need Help?

If you run into problems:

1. **Check the [Troubleshooting Guide](docs/troubleshooting.md)** - Solutions to common issues
2. **Read the [FAQ](docs/faq.md)** - Answers to frequently asked questions
3. **Review the [Installation Guide](docs/installation.md)** - Make sure you followed all steps
4. **Check your logs** - Run `docker compose logs` to see error messages

## Security Best Practices

- Never share your `.env` file publicly - it may contain sensitive information
- Use strong passwords for your Portainer admin account
- Keep Edge Keys secret if using Edge Agent mode
- Use HTTPS connections when possible
- Regularly backup your Portainer data
- Keep Portainer updated with `docker compose pull`

## License

MIT License - See LICENSE file for details

## Additional Resources

- [Official Portainer Documentation](https://docs.portainer.io)
- [Portainer Forums](https://forums.portainer.io)
- [Docker Documentation](https://docs.docker.com)

---

**Ready to get started?** Begin with the [Getting Started Guide](docs/getting-started.md)
