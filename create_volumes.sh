#!/bin/bash

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with sudo privileges"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if docker-compose.yml exists
DOCKER_COMPOSE_FILE="$(dirname "$0")/docker-compose.yml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "Error: docker-compose.yml not found at $DOCKER_COMPOSE_FILE"
    exit 1
fi

echo "Creating required directories based on docker-compose.yml volumes..."

# Extract volume paths from docker-compose.yml
echo "Extracting volume paths from docker-compose.yml..."

# Create a base directory for all volumes
BASE_DIR="/storage/portainer"
mkdir -p "$BASE_DIR"
echo "✓ Created base directory $BASE_DIR"

# Extract device paths from docker-compose.yml using grep and awk
echo "Extracting volume paths from docker-compose.yml..."
DEVICE_PATHS=$(grep -A 2 "device:" "$DOCKER_COMPOSE_FILE" | grep "device:" | awk '{print $2}')

# Check if we found any paths
if [ -z "$DEVICE_PATHS" ]; then
    echo "Error: No volume device paths found in docker-compose.yml"
    exit 1
fi

# Create directories for each path
echo "Creating directories for extracted paths..."
while IFS= read -r path; do
    if [ -n "$path" ]; then
        if mkdir -p "$path"; then
            echo "✓ Created $path"
        else
            echo "✗ Failed to create $path"
            exit 1
        fi
    fi
done <<< "$DEVICE_PATHS"

# Set appropriate permissions
if chmod -R 777 "$BASE_DIR"; then
    echo "✓ Set permissions for $BASE_DIR"
else
    echo "✗ Failed to set permissions for $BASE_DIR"
    exit 1
fi

echo "✓ All required directories have been created successfully!"
echo "✓ You can now run 'docker-compose up -d' to start the Portainer service."