# Troubleshooting Guide

This guide helps you solve common problems you might encounter when using Portainer. Each issue includes symptoms, possible causes, and step-by-step solutions.

## Portainer Won't Start

### Symptoms
- Running `docker compose up -d` shows an error
- Portainer container doesn't appear in `docker ps`
- Web interface won't load

### Possible Causes
1. Docker isn't running
2. Port already in use
3. Configuration file has errors
4. Insufficient permissions

### Solutions

#### Check if Docker is Running

```bash
docker ps
```

If this shows an error, Docker isn't running. Start Docker:
- **Linux:** `sudo systemctl start docker`
- **Mac:** Open Docker Desktop application
- **Windows:** Open Docker Desktop application

#### Check if Port is Already in Use

```bash
# Linux/Mac
netstat -tulpn | grep 9000

# Or use lsof
lsof -i :9000
```

If something is using port 9000, either:
- Stop the other service, or
- Change Portainer's port in `.env` (see [Configuration Guide](configuration.md))

#### Check Configuration File

Make sure your `.env` file exists and is properly formatted:

```bash
cat .env
```

Look for:
- Missing quotes around values
- Extra spaces at the end of lines
- Typos in variable names

If you made changes, restart Portainer:
```bash
docker compose down
docker compose up -d
```

#### Check Permissions

If you get permission errors:

```bash
# Make sure storage directories exist
sudo ./create_volumes.sh

# Check Docker permissions
sudo docker ps
```

If you need to run Docker without sudo, add your user to the docker group:
```bash
sudo usermod -aG docker $USER
# Then log out and log back in
```

---

## Can't Access Portainer Web Interface

### Symptoms
- Portainer container is running (`docker ps` shows it)
- Browser shows "Connection refused" or "This site can't be reached"
- Page won't load

### Possible Causes
1. Wrong port number
2. Firewall blocking the port
3. Using wrong address (localhost vs IP)
4. Portainer not fully started yet

### Solutions

#### Verify Port Number

Check what port Portainer is using:

```bash
grep PORTAINER_PORT .env
```

Make sure you're using the correct port in your browser:
- If `PORTAINER_PORT=9000`, use `http://localhost:9000`
- If `PORTAINER_PORT=9443`, use `http://localhost:9443`

#### Check if Portainer is Ready

Sometimes Portainer takes a moment to start:

```bash
docker compose logs
```

Look for any error messages. If you see "Server listening on :9000", it's ready.

#### Try Different Address

If you're on a remote server, use the server's IP instead of localhost:

```bash
# Find your IP
ip addr show
# or
hostname -I
```

Then use `http://your-ip:9000` in your browser.

#### Check Firewall

If you're on a remote server, the firewall might be blocking the port:

```bash
# Check firewall status (Ubuntu/Debian)
sudo ufw status

# Allow the port
sudo ufw allow 9000/tcp
```

For other systems, check your firewall documentation.

---

## Edge Agent Won't Connect

### Symptoms
- Edge Agent container is running
- Portainer Server shows environment as "Down" or "Offline"
- Can't manage the remote computer

### Possible Causes
1. Wrong Edge ID or Edge Key
2. Network connectivity issues
3. Firewall blocking connection
4. Portainer Server not accessible

### Solutions

#### Verify Edge Credentials

Check your `.env` file:

```bash
grep PORTAINER_EDGE .env
```

Make sure:
- `PORTAINER_EDGE_ID` matches exactly what Portainer Server gave you
- `PORTAINER_EDGE_KEY` is complete and not truncated
- No extra spaces or characters

If you're unsure, regenerate the Edge Key in Portainer Server and update your `.env`.

#### Check Network Connectivity

From the agent computer, can you reach the Portainer Server?

```bash
# Replace with your server's address
ping your-portainer-server.com
curl http://your-portainer-server.com:9000
```

If you can't reach it, check:
- Internet connection
- DNS resolution
- Server is actually running

#### Check Agent Logs

```bash
docker compose logs
```

Look for connection errors or authentication failures.

#### Restart the Agent

Sometimes a simple restart helps:

```bash
docker compose down
docker compose up -d
```

#### Check Insecure Polling Setting

If your Portainer Server doesn't use HTTPS, you might need:

```bash
PORTAINER_EDGE_INSECURE_POLL=1
```

Add this to your `.env` file and restart the agent.

---

## Storage or Volume Errors

### Symptoms
- Errors about missing directories
- Permission denied when accessing data
- Portainer won't save settings

### Possible Causes
1. Storage directories weren't created
2. Wrong permissions on folders
3. Disk is full
4. Wrong storage path in configuration

### Solutions

#### Recreate Storage Directories

```bash
sudo ./create_volumes.sh
```

This script creates all necessary directories with the right permissions.

#### Check Storage Path

Verify the storage path in your `.env`:

```bash
grep DEFAULT_STORAGE_FOLDER .env
```

Make sure this path exists on your system:

```bash
ls -la /storage/portainer
```

If the path is wrong, either:
- Create the directory, or
- Update the path in `.env` and run `create_volumes.sh` again

#### Check Disk Space

Make sure you have enough disk space:

```bash
df -h
```

If disk is full, free up space or move to a larger drive.

#### Fix Permissions

```bash
# Set correct permissions on storage folder
sudo chmod -R 777 /storage/portainer
```

For better security, you can use more restrictive permissions, but 777 ensures everything works.

---

## Network Errors

### Symptoms
- "Network not found" errors
- Containers can't communicate
- Overlay network issues in Swarm mode

### Possible Causes
1. Network wasn't created
2. Wrong network name in configuration
3. Network driver issues

### Solutions

#### Create the Network

```bash
# Check what network name is configured
grep SHARED_DOCKER_NETWORK .env

# Create the network (replace with your network name)
docker network create cloudflared_shared-network
```

#### Check Existing Networks

```bash
docker network ls
```

Look for your network in the list. If it exists but with a different name, update your `.env`.

#### Remove and Recreate Network

```bash
docker network rm cloudflared_shared-network
docker network create cloudflared_shared-network
```

Then restart Portainer:
```bash
docker compose down
docker compose up -d
```

---

## Container Keeps Restarting

### Symptoms
- `docker ps` shows container restarting repeatedly
- Status shows "Restarting" instead of "Up"
- Can't access web interface

### Possible Causes
1. Configuration error
2. Resource constraints
3. Dependency failure
4. Crash loop

### Solutions

#### Check Container Logs

```bash
docker compose logs
```

Look for error messages that explain why it's crashing.

#### Check Container Status

```bash
docker compose ps
```

This shows how many times the container has restarted.

#### Check System Resources

```bash
# Check memory
free -h

# Check disk space
df -h

# Check CPU
top
```

If resources are low, you might need to free up space or add more resources.

#### Try Clean Restart

```bash
# Stop everything
docker compose down

# Remove volumes (WARNING: this deletes data!)
docker volume rm portainer_portainer_data

# Start fresh
docker compose up -d
```

**Warning:** This will delete all your Portainer data. Only do this if you're okay losing your settings.

---

## Performance Issues

### Symptoms
- Portainer web interface is slow
- Pages take a long time to load
- High CPU or memory usage

### Possible Causes
1. Too many containers
2. Limited system resources
3. Large logs
4. Database needs optimization

### Solutions

#### Check Resource Usage

```bash
docker stats
```

This shows CPU and memory usage for all containers.

#### Reduce Log Level

If logging is set to DEBUG, change it to INFO:

```bash
# Edit .env
PORTAINER_LOG_LEVEL=INFO

# Restart Portainer
docker compose down
docker compose up -d
```

#### Clean Up Old Containers

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune
```

#### Check Database Size

If Portainer has been running a long time, the database might be large. Consider:
- Exporting important configurations
- Starting fresh with a new installation

---

## After Docker Update

### Symptoms
- Portainer stopped working after Docker update
- Version mismatch errors
- API compatibility issues

### Solutions

#### Restart Portainer

```bash
docker compose down
docker compose up -d
```

#### Pull Latest Images

```bash
docker compose pull
docker compose up -d
```

#### Check Docker Version Compatibility

```bash
docker --version
docker-compose --version
```

Make sure your Docker Compose version is compatible with your Docker version.

---

## Getting More Help

If none of these solutions work:

### Collect Diagnostic Information

```bash
# Save this information to share with support
docker version > docker-info.txt
docker-compose version >> docker-info.txt
docker ps >> docker-info.txt
docker compose ps >> docker-info.txt
docker compose logs >> docker-info.txt
cat .env >> docker-info.txt
```

### Check Portainer Documentation

Visit the official Portainer documentation for more advanced issues:
- https://docs.portainer.io

### Community Support

- Portainer Forum: https://forums.portainer.io
- GitHub Issues: Check if others have similar problems

---

## Prevention Tips

### Regular Backups

Back up your Portainer data regularly:

```bash
# Backup the data volume
docker run --rm -v portainer_portainer_data:/data -v $(pwd):/backup alpine tar czf /backup/portainer-backup.tar.gz /data
```

### Keep Software Updated

```bash
# Update Portainer images
docker compose pull
docker compose up -d
```

### Monitor Logs Regularly

```bash
# Check logs for warnings
docker compose logs | grep -i warning
```

### Document Your Configuration

Keep notes about:
- Which mode you're using
- Custom settings in `.env`
- Any special configurations
- Network setup

This makes troubleshooting easier if problems occur.

---

## Quick Reference: Common Commands

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

# Update Portainer
docker compose pull
docker compose up -d

# Check Docker status
docker ps

# Check network
docker network ls

# Check volumes
docker volume ls
```

---

## Still Stuck?

If you've tried these solutions and still have problems:

1. **Start fresh** - Sometimes a clean installation is faster than debugging
2. **Check system logs** - Look at `/var/log/syslog` or `journalctl` for system-level errors
3. **Try a different mode** - If Edge Agent isn't working, try Host Mode to isolate the issue
4. **Ask for help** - Provide the diagnostic information you collected above

Remember: Most problems are solved by checking the basics - is Docker running? Are the ports correct? Is the network configured properly? Start simple before diving into complex solutions.
