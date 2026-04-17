# Installation Guide

This guide will walk you through installing Portainer on your computer step by step. We'll start with the most common setup - running Portainer on a single computer with its web interface.

## Before You Begin

Make sure you have:
- Docker installed and running on your system
- Access to a terminal or command prompt
- Administrator privileges (sudo on Linux/Mac, or Administrator on Windows)

## Step 1: Download the Project Files

First, you need to get the configuration files for this project.

### Option A: Using Git (Recommended)

If you have git installed, run:

```bash
git clone <repository-url>
cd portainer-compose
```

### Option B: Download and Extract

1. Download the project files as a ZIP file
2. Extract the ZIP file to a folder on your computer
3. Open a terminal and navigate to that folder

## Step 2: Choose Your Setup Mode

You need to decide how you want to use Portainer. For most users, we recommend the **Host Mode** (single computer setup).

### For Single Computer Setup (Host Mode)

Run this command to set up Portainer with its web interface:

```bash
cp docker-compose-host.yml docker-compose.yml
```

This tells the system to use the configuration that includes the Portainer web interface.

### For Remote Agent Setup (Edge Agent Mode)

If you already have a Portainer server elsewhere and want this computer to be managed remotely:

```bash
cp docker-compose-edge-agent.yml docker-compose.yml
```

**Note:** If you're not sure which to choose, use the Host Mode (first option). You can always change it later.

## Step 3: Set Up Your Configuration File

The project uses a configuration file called `.env` to store your settings. Let's create it from the example template.

```bash
cp .env.example .env
```

This creates your personal configuration file. You can edit this file to customize your settings (see [Configuration Guide](configuration.md) for details).

## Step 4: Create the Storage Directory

Portainer needs a place to store its data. We'll create this directory and set the right permissions.

Run this command:

```bash
sudo ./create_volumes.sh
```

**What this does:**
- Creates the storage folder for Portainer data
- Sets the correct permissions so Portainer can access it
- You'll need to enter your password (the `sudo` part)

**Why sudo?** The storage folder is created in a system location that requires administrator access.

## Step 5: Create the Docker Network

Portainer needs a network to communicate. Let's create it.

First, check what network name is set in your `.env` file (default is `cloudflared_shared-network`):

```bash
grep SHARED_DOCKER_NETWORK .env
```

Then create the network:

```bash
docker network create cloudflared_shared-network
```

If you changed the network name in your `.env` file, use that name instead.

**Note:** If you get an error saying the network already exists, that's fine - you can skip this step.

## Step 6: Start Portainer

Now let's start Portainer!

```bash
docker compose up -d
```

**What this does:**
- Downloads the Portainer software (if not already downloaded)
- Starts Portainer in the background
- Sets it to automatically restart if your computer restarts

**What the flags mean:**
- `up` - starts the services
- `-d` - runs in "detached" mode (in the background)

## Step 7: Verify It's Running

Check that Portainer is running correctly:

```bash
docker ps
```

You should see a container named `portainer` in the list with a status of "Up".

## Step 8: Access the Portainer Web Interface

### Find Your Port Number

Check which port Portainer is using:

```bash
grep PORTAINER_PORT .env
```

The default is `9000`.

### Open Your Web Browser

Open a web browser and go to:

```
http://localhost:9000
```

Replace `9000` with your port number if you changed it.

If you're installing on a remote server, use the server's IP address instead:

```
http://your-server-ip:9000
```

## Step 9: Set Up Your Admin Account

The first time you access Portainer, you'll see a setup screen:

1. **Create a username** - Choose a username for your admin account
2. **Create a password** - Choose a strong password (at least 12 characters recommended)
3. **Confirm your password** - Type it again to make sure it's correct
4. **Click "Create user"** - This creates your admin account

## Step 10: Connect to Your Docker Environment

After creating your account, Portainer will ask you to connect to a Docker environment:

1. **Select "Get Started"** - This connects to the Docker on your current computer
2. **Give it a name** - You can call it "Local" or "My Computer" or anything you like
3. **Click "Connect"** - Portainer will connect to your Docker installation

## Congratulations! You're Done!

You should now see the Portainer dashboard. From here you can:
- View and manage your Docker containers
- Create new containers
- View logs and statistics
- And much more!

## What If Something Goes Wrong?

If you encounter any problems:
- Check the [Troubleshooting Guide](troubleshooting.md) for common issues
- Make sure Docker is running: `docker ps`
- Check that Portainer is running: `docker compose ps`
- Look at the logs: `docker compose logs`

## Stopping Portainer

If you need to stop Portainer temporarily:

```bash
docker compose down
```

To start it again:

```bash
docker compose up -d
```

## Completely Removing Portainer

If you want to remove Portainer entirely:

```bash
# Stop and remove containers
docker compose down

# Remove the volumes (this deletes all Portainer data!)
docker volume rm portainer_portainer_data

# Remove the network (if you want)
docker network rm cloudflared_shared-network
```

**Warning:** Removing volumes will delete all your Portainer settings and data. Make sure you want to do this!

## Next Steps

Now that Portainer is installed:
- Learn about [Configuration options](configuration.md) to customize your setup
- Explore the [Deployment Modes](deployment-modes.md) if you need to manage multiple computers
- Check out the [FAQ](faq.md) for common questions
