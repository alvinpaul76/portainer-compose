#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with sudo privileges"
    echo "Usage: sudo $0 <host|nginx|edge-agent>"
    exit 1
fi

# Target deployment: host, nginx or edge-agent
TARGET="$1"
if [ "$TARGET" != "host" ] && [ "$TARGET" != "nginx" ] && [ "$TARGET" != "edge-agent" ]; then
    echo "Usage: sudo $0 <host|nginx|edge-agent>"
    exit 1
fi

# Check if .env exists and load it
ENV_FILE="$SCRIPT_DIR/$TARGET/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Create it first: cp $TARGET/.env.example $TARGET/.env"
    exit 1
fi

# Load KEY=VALUE pairs from .env without executing them as shell code
# (values such as <placeholders> would break `source`)
while IFS= read -r line || [ -n "$line" ]; do
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue
    value="${BASH_REMATCH[2]}"
    value="${value%\"}"; value="${value#\"}"
    value="${value%\'}"; value="${value#\'}"
    export "${BASH_REMATCH[1]}=$value"
done < "$ENV_FILE"

# Check if docker-compose.yml exists
DOCKER_COMPOSE_FILE="$SCRIPT_DIR/$TARGET/docker-compose.yml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "Error: docker-compose.yml not found at $DOCKER_COMPOSE_FILE"
    exit 1
fi

# Resolve all ${VAR} references in a string, including nested variables.
# Fails with an error if any referenced variable is undefined.
resolve_variables() {
    local input="$1"
    # Reduce ${VAR:?msg} / ${VAR:-default} to ${VAR}; the value must come from .env
    local resolved
    resolved=$(sed -E 's/\$\{([A-Za-z_][A-Za-z0-9_]*):[-?][^}]*\}/${\1}/g' <<< "$input")
    local max_passes=10
    local pass=0

    while [[ "$resolved" =~ \$\{([a-zA-Z_][a-zA-Z0-9_]*)\} ]]; do
        if (( pass >= max_passes )); then
            echo "Error: Exceeded maximum variable resolution depth for: $input" >&2
            exit 1
        fi

        local var_name="${BASH_REMATCH[1]}"
        if [ -z "${!var_name+x}" ]; then
            echo "Error: Variable '\${$var_name}' referenced in docker-compose.yml is not defined in $TARGET/.env" >&2
            exit 1
        fi

        resolved="${resolved/\$\{$var_name\}/${!var_name}}"
        (( pass++ ))
    done

    echo "$resolved"
}

echo "Creating required directories based on docker-compose.yml volumes..."

# Extract raw device paths from docker-compose.yml using grep and awk
echo "Extracting volume paths from docker-compose.yml..."
RAW_DEVICE_PATHS=$(grep -A 2 "device:" "$DOCKER_COMPOSE_FILE" | grep "device:" | sed -E 's/^[[:space:]]*device:[[:space:]]*//')

# Check if we found any paths
if [ -z "$RAW_DEVICE_PATHS" ]; then
    echo "✓ $TARGET uses no bind-mounted volumes; nothing to create."
    exit 0
fi

# Resolve variables in each path and collect resolved paths
RESOLVED_PATHS=()
while IFS= read -r raw_path; do
    if [ -n "$raw_path" ]; then
        resolved_path=$(resolve_variables "$raw_path")
        RESOLVED_PATHS+=("$resolved_path")
    fi
done <<< "$RAW_DEVICE_PATHS"

# Determine base directory from DEFAULT_STORAGE_FOLDER env var or fall back to common prefix
if [ -n "${DEFAULT_STORAGE_FOLDER+x}" ]; then
    BASE_DIR=$(resolve_variables "${DEFAULT_STORAGE_FOLDER}")
else
    echo "✗ DEFAULT_STORAGE_FOLDER environment variable is not defined in $TARGET/.env"
    exit 1
fi

mkdir -p "$BASE_DIR"
echo "✓ Created base directory $BASE_DIR"

# Create directories for each resolved path
echo "Creating directories for extracted paths..."
for path in "${RESOLVED_PATHS[@]}"; do
    if mkdir -p "$path"; then
        echo "✓ Created $path"
    else
        echo "✗ Failed to create $path"
        exit 1
    fi
done

# Set restrictive permissions (owner rwx, group rx, no access for others)
if chmod -R 750 "$BASE_DIR"; then
    echo "✓ Set permissions for $BASE_DIR"
else
    echo "✗ Failed to set permissions for $BASE_DIR"
    exit 1
fi

echo "✓ All required directories have been created successfully!"
echo "✓ You can now run 'docker compose up -d' inside $TARGET/ to start Portainer."
