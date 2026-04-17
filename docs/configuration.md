# Configuration Guide

This guide explains the settings you can customize in Portainer. All settings are stored in the `.env` file in the project folder.

## What is the .env File?

The `.env` file is a configuration file that stores your personal settings. It's like a preferences file for Portainer. When you first install Portainer, you copy this from `.env.example` and then customize it.

**Important:** Never share your `.env` file publicly if it contains sensitive information like passwords or keys.

## Basic Configuration

These are the main settings you might want to change.

### Network Name

**Setting:** `SHARED_DOCKER_NETWORK`

**Default value:** `cloudflared_shared-network`

**What it does:** This is the name of the network that Portainer uses to communicate. Think of it like a private network cable connecting Portainer to your containers.

**When to change it:** 
- If you already have a network with this name
- If you want to use a different network name
- If you're running multiple Portainer instances

**Example:**
```bash
SHARED_DOCKER_NETWORK=my_custom_network
```

### Storage Location

**Setting:** `DEFAULT_STORAGE_FOLDER`

**Default value:** `/storage/portainer`

**What it does:** This is where Portainer stores all its data on your computer. This includes your settings, user information, and any data you create in Portainer.

**When to change it:**
- If you want to store data on a different drive
- If you have limited space in the default location
- If you want to use an external storage device

**Example:**
```bash
DEFAULT_STORAGE_FOLDER=/mnt/external_drive/portainer
```

**Important:** Make sure the location you choose has enough space and appropriate permissions.

### Portainer Web Port

**Setting:** `PORTAINER_PORT`

**Default value:** `9000`

**What it does:** This is the port number you use to access the Portainer web interface. When you type `http://localhost:9000`, the `9000` is this port.

**When to change it:**
- If port 9000 is already used by another program
- If you want to use a different port for security reasons
- If you're running multiple web services

**Example:**
```bash
PORTAINER_PORT=9443
```

Then you would access Portainer at `http://localhost:9443`

**Note:** After changing this, you'll need to restart Portainer:
```bash
docker compose down
docker compose up -d
```

## Edge Agent Configuration

These settings are only needed if you're using Edge Agent mode (connecting this computer to a remote Portainer server).

### Edge Agent Port

**Setting:** `PORTAINER_AGENT_PORT`

**Default value:** `9001`

**What it does:** The port number used by the Edge Agent to communicate with the Portainer server.

**When to change it:**
- If port 9001 is already in use
- If you have specific firewall requirements

### Edge ID

**Setting:** `PORTAINER_EDGE_ID`

**Default value:** `<replace_with_edge_id>`

**What it does:** A unique identifier that tells the Portainer server which computer this is.

**How to get it:**
1. Log in to your Portainer server
2. Go to "Environments"
3. Click "Add environment"
4. Choose "Edge Agent"
5. Copy the Edge ID that's generated

**Example:**
```bash
PORTAINER_EDGE_ID=abc123def456
```

**Important:** This is a unique identifier - don't share it publicly.

### Edge Key

**Setting:** `PORTAINER_EDGE_KEY`

**Default value:** `<replace_with_edge_key>`

**What it does:** A security key that authenticates this computer with the Portainer server. It contains connection information and a security token.

**How to get it:**
1. Follow the same steps as for Edge ID above
2. Copy the Edge Key that's generated

**Example:**
```bash
PORTAINER_EDGE_KEY=aVeryLongStringOfCharactersThatIncludesTheServerURLAndToken
```

**Security note:** Treat this like a password. Don't share it publicly or commit it to git repositories.

### Insecure Polling

**Setting:** `PORTAINER_EDGE_INSECURE_POLL`

**Default value:** `0`

**What it does:** Controls whether the Edge Agent can connect without encryption (HTTPS).

**Values:**
- `0` (default) - Requires secure HTTPS connection (recommended)
- `1` - Allows insecure HTTP connection (only for testing)

**When to change it:**
- Only set to `1` for development or testing
- Always keep it at `0` for production use
- If your Portainer server doesn't have HTTPS set up

**Example:**
```bash
PORTAINER_EDGE_INSECURE_POLL=1
```

### Log Level

**Setting:** `PORTAINER_LOG_LEVEL`

**Default value:** `DEBUG`

**What it does:** Controls how much detail is shown in the logs.

**Values:**
- `DEBUG` - Shows all details (useful for troubleshooting)
- `INFO` - Shows normal information (recommended for most users)
- `WARN` - Shows only warnings
- `ERROR` - Shows only errors

**When to change it:**
- Use `INFO` for normal operation to reduce log size
- Use `DEBUG` if you're having problems and need more details
- Use `WARN` or `ERROR` if you want minimal logging

**Example:**
```bash
PORTAINER_LOG_LEVEL=INFO
```

## How to Edit the Configuration

### Step 1: Open the File

Open the `.env` file in a text editor:
- On Linux/Mac: You can use `nano .env` or any text editor
- On Windows: Use Notepad, VS Code, or any text editor

### Step 2: Make Your Changes

Find the setting you want to change and update its value. For example:

```bash
# Before
PORTAINER_PORT=9000

# After
PORTAINER_PORT=9443
```

### Step 3: Save the File

Save the file and close your editor.

### Step 4: Restart Portainer

For most changes to take effect, you need to restart Portainer:

```bash
docker compose down
docker compose up -d
```

## Common Configuration Examples

### Example 1: Using a Different Storage Drive

If you want to store Portainer data on an external drive mounted at `/mnt/data`:

```bash
DEFAULT_STORAGE_FOLDER=/mnt/data/portainer
```

Then run the volume creation script again:
```bash
sudo ./create_volumes.sh
```

### Example 2: Changing the Web Port

If port 9000 is already used by another application:

```bash
PORTAINER_PORT=9443
```

Restart Portainer and access it at `http://localhost:9443`

### Example 3: Setting Up Edge Agent

To connect this computer to a Portainer server:

```bash
PORTAINER_EDGE_ID=your-edge-id-here
PORTAINER_EDGE_KEY=your-edge-key-here
PORTAINER_EDGE_INSECURE_POLL=0
PORTAINER_LOG_LEVEL=INFO
```

## Security Best Practices

1. **Never commit .env to version control** - The `.env` file often contains sensitive information. Add it to your `.gitignore` file.

2. **Use strong passwords** - When creating your Portainer admin account, use a strong, unique password.

3. **Keep Edge Key secret** - If using Edge Agent mode, never share your Edge Key publicly.

4. **Use HTTPS** - Keep `PORTAINER_EDGE_INSECURE_POLL=0` for production use.

5. **Limit permissions** - Only give necessary permissions to the storage folder.

## Troubleshooting Configuration Issues

### Changes Not Taking Effect

If you changed a setting but nothing seems different:
1. Make sure you saved the `.env` file
2. Restart Portainer: `docker compose down && docker compose up -d`
3. Check that the setting is formatted correctly (no extra spaces, correct syntax)

### Port Already in Use

If you get an error that a port is already in use:
1. Check what's using the port: `netstat -tulpn | grep 9000` (Linux)
2. Either stop the other service or change Portainer's port in `.env`

### Permission Errors

If you get permission errors:
1. Make sure you ran `sudo ./create_volumes.sh` to set up folders
2. Check that the storage folder exists and has the right permissions
3. On Linux/Mac, you may need to use sudo for some operations

## Need More Help?

- Check the [Installation Guide](installation.md) for setup help
- See [Troubleshooting](troubleshooting.md) for common problems
- Review the [FAQ](faq.md) for frequently asked questions
