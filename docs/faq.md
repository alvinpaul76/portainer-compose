# Frequently Asked Questions

This page answers the most common questions about Portainer and this project. If you don't find your answer here, check the [Troubleshooting Guide](troubleshooting.md) or [Installation Guide](installation.md).

## General Questions

### What is Portainer?

Portainer is a web-based tool that makes it easy to manage Docker containers. Instead of using command-line tools, you can use a friendly graphical interface to create, start, stop, and manage your containers.

### Do I need to know Docker to use Portainer?

While Portainer makes Docker easier, having basic Docker knowledge helps. However, you can learn as you go - Portainer's interface is designed to be intuitive even for beginners.

### Is Portainer free?

Yes! Portainer Community Edition (CE) is free and open source. There's also a paid Enterprise Edition with additional features, but the free version is sufficient for most users.

### What operating systems does Portainer support?

Portainer runs on any system that supports Docker, including:
- Linux (Ubuntu, Debian, CentOS, etc.)
- macOS
- Windows
- Most cloud platforms

### What are the system requirements?

Minimum requirements:
- Docker installed and running
- At least 1GB of RAM (2GB recommended)
- 10GB of free disk space for data
- Basic computer skills and terminal access

## Installation Questions

### How long does installation take?

Typical installation takes 5-15 minutes:
- Downloading files: 1-2 minutes
- Configuration: 2-3 minutes
- Running setup commands: 2-5 minutes
- First-time setup in web browser: 2-5 minutes

### Can I install Portainer without sudo?

Some steps require sudo (administrator) privileges, particularly:
- Creating storage directories
- Setting file permissions
- Creating Docker networks

You can run Docker commands without sudo after adding your user to the docker group, but initial setup typically requires sudo.

### Do I need to use the command line?

Yes, for installation you'll need to use a terminal or command prompt. However, once Portainer is installed, you can do almost everything through the web interface without using commands.

### Can I install Portainer on a remote server?

Yes! You can install Portainer on any server you can access via SSH. After installation, you'll access the web interface using the server's IP address instead of localhost.

### What if I mess up the installation?

Don't worry! You can always start fresh:
```bash
docker compose down
docker volume rm portainer_portainer_data
```

Then follow the installation guide again. Your Docker containers and images won't be affected - only Portainer's settings are removed.

## Configuration Questions

### Which deployment mode should I choose?

For most users, start with **Host Mode** (Portainer Server). This gives you a web interface on your computer. Choose Edge Agent mode only if you already have a Portainer server elsewhere and want to connect this computer to it.

See [Deployment Modes](deployment-modes.md) for a detailed comparison.

### Can I change the port number?

Yes! Edit the `.env` file and change `PORTAINER_PORT` to your desired port. Then restart Portainer:
```bash
docker compose down
docker compose up -d
```

### Where is my data stored?

By default, Portainer stores data in `/storage/portainer/data`. You can change this in the `.env` file by modifying `DEFAULT_STORAGE_FOLDER`.

### Do I need to backup my data?

Yes, it's a good practice to backup your Portainer data regularly. This includes your user accounts, settings, and configurations. See the [Troubleshooting Guide](troubleshooting.md) for backup commands.

### Can I use a different storage location?

Yes! Edit `DEFAULT_STORAGE_FOLDER` in your `.env` file to point to your desired location. Then run:
```bash
sudo ./create_volumes.sh
docker compose down
docker compose up -d
```

## Usage Questions

### How do I access Portainer?

Open a web browser and go to `http://localhost:9000` (or your configured port). If you're on a remote server, use the server's IP address: `http://your-server-ip:9000`.

### I forgot my Portainer password. What do I do?

You'll need to reset Portainer:
```bash
docker compose down
docker volume rm portainer_portainer_data
docker compose up -d
```

Then access Portainer again and create a new admin account. **Warning:** This will delete all your Portainer settings.

### Can I manage multiple computers with one Portainer?

Yes! You can add agents to other computers and manage them from your central Portainer server. See [Deployment Modes](deployment-modes.md) for the Edge Agent setup.

### How do I add a new Docker environment?

In Portainer:
1. Go to "Environments" in the left menu
2. Click "Add environment"
3. Choose the type (Docker Standalone, Edge Agent, etc.)
4. Follow the setup wizard

### Can I use Portainer with Docker Swarm?

Yes, Portainer supports Docker Swarm. However, this project's default setup is for single-node deployments. Swarm configuration requires additional setup not included in this project.

## Security Questions

### Is Portainer secure?

Portainer is secure when configured properly:
- Always use strong passwords for your admin account
- Keep Edge Keys secret if using Edge Agent mode
- Use HTTPS when possible (keep `PORTAINER_EDGE_INSECURE_POLL=0`)
- Don't expose Portainer directly to the internet without a reverse proxy
- Keep Portainer updated to the latest version

### Should I put Portainer on the public internet?

It's not recommended to expose Portainer directly to the internet. Instead:
- Use a VPN to access it remotely
- Put it behind a reverse proxy with authentication
- Use firewall rules to restrict access
- Consider using Edge Agent mode for remote management

### How do I update Portainer?

```bash
docker compose pull
docker compose up -d
```

This downloads the latest version and restarts Portainer with minimal downtime.

### What happens if my Edge Key is compromised?

If your Edge Key is leaked:
1. In Portainer Server, regenerate the Edge Key for that environment
2. Update the `PORTAINER_EDGE_KEY` in your `.env` file on the agent
3. Restart the agent: `docker compose restart`

### Can I use Portainer without exposing any ports?

For Edge Agent mode, yes - the agent initiates the connection to the server, so you don't need to open incoming ports. For Host Mode, you need at least one port open for the web interface.

## Troubleshooting Questions

### Portainer won't start. What should I check?

Check these in order:
1. Is Docker running? (`docker ps`)
2. Is the port already in use? (`netstat -tulpn | grep 9000`)
3. Are the storage directories created? (`ls -la /storage/portainer`)
4. Check the logs: `docker compose logs`

See the [Troubleshooting Guide](troubleshooting.md) for detailed solutions.

### I can't access the web interface. Why?

Common reasons:
- Wrong port number in the URL
- Firewall blocking the port
- Using localhost when you should use the server's IP
- Portainer not fully started yet

Try waiting 30 seconds and refreshing, or check `docker compose ps` to see if Portainer is running.

### The Edge Agent shows as "Offline". What's wrong?

Check:
1. Edge ID and Edge Key are correct in `.env`
2. The agent can reach the Portainer Server (try `ping` or `curl`)
3. Network connectivity between the computers
4. Check agent logs: `docker compose logs`

See the [Troubleshooting Guide](troubleshooting.md) for more details.

### How do I view Portainer logs?

```bash
docker compose logs
```

For real-time log viewing:
```bash
docker compose logs -f
```

## Advanced Questions

### Can I run multiple Portainer instances?

Yes, but each instance needs:
- Different port numbers
- Different storage directories
- Different network names

Update these in your `.env` file for each instance.

### Can I use Portainer with Kubernetes?

Yes, Portainer supports Kubernetes, but that requires a different installation method. This project is specifically for Docker/Docker Compose deployments.

### How do I migrate Portainer to a new server?

1. Backup your data: See backup commands in [Troubleshooting Guide](troubleshooting.md)
2. Install Portainer on the new server
3. Restore your backup
4. Update any Edge Agents to point to the new server

### Can I use Portainer in production?

Yes, Portainer is used in production by many organizations. For production use:
- Use strong passwords and authentication
- Implement proper backup procedures
- Consider the Enterprise Edition for advanced features
- Use HTTPS and secure connections
- Monitor logs and performance

### How do I uninstall Portainer completely?

```bash
# Stop and remove containers
docker compose down

# Remove volumes (deletes all data)
docker volume rm portainer_portainer_data

# Remove the network
docker network rm cloudflared_shared-network

# Delete the project files if desired
```

**Warning:** This will delete all Portainer data and settings.

## Project-Specific Questions

### What's the difference between docker-compose.yml and the template files?

- `docker-compose-host.yml` - Template for Portainer Server with web interface
- `docker-compose-edge-agent.yml` - Template for Edge Agent only
- `docker-compose.yml` - The active file (copy one of the templates to this name)

You choose which template to use based on your needs, then copy it to `docker-compose.yml`.

### Why do I need to run create_volumes.sh with sudo?

The script creates directories in `/storage`, which is a system location that requires administrator access. It also sets permissions that need elevated privileges.

### What is the shared network for?

The shared network (`cloudflared_shared-network` by default) allows Portainer to communicate with other services. If you're using other Docker services that need to communicate with Portainer, they should join this network.

### Can I modify the docker-compose files?

Yes! The files are templates you can customize. However, if you're new to Portainer, it's best to start with the default configuration before making changes.

### Do I need to keep the .env file secret?

The `.env` file can contain sensitive information like Edge Keys. Never commit it to public repositories. If you're using version control, add `.env` to your `.gitignore` file.

## Still Have Questions?

If you don't find your answer here:

- Check the [Troubleshooting Guide](troubleshooting.md) for common problems
- Review the [Installation Guide](installation.md) for setup help
- Read the [Configuration Guide](configuration.md) for settings details
- Visit the official Portainer documentation: https://docs.portainer.io
- Ask in the Portainer forums: https://forums.portainer.io

## Quick Tips

- **Start simple** - Begin with Host Mode on a single computer
- **Take backups** - Regularly backup your Portainer data
- **Keep updated** - Run `docker compose pull` regularly to get updates
- **Check logs** - Use `docker compose logs` when something goes wrong
- **Document settings** - Keep notes about your configuration for future reference
- **Test changes** - Try configuration changes in a test environment first
