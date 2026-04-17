#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"

# Check if script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run with sudo privileges"
    echo "Please run: sudo $0"
    exit 1
fi

# Check if .env exists and load it
ENV_FILE="$SCRIPT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Load .env into current environment, ignoring comments and empty lines
set -o allexport
# shellcheck disable=SC1090
source <(grep -v '^\s*#' "$ENV_FILE" | grep -v '^\s*$')
set +o allexport

# Check if docker-compose.yml exists
DOCKER_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
if [ ! -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "Error: docker-compose.yml not found at $DOCKER_COMPOSE_FILE"
    exit 1
fi

# Resolve all ${VAR} references in a string, including nested variables.
# Fails with an error if any referenced variable is undefined.
resolve_variables() {
    local input="$1"
    local resolved="$input"
    local max_passes=10
    local pass=0

    while [[ "$resolved" =~ \$\{([a-zA-Z_][a-zA-Z0-9_]*)\} ]]; do
        if (( pass >= max_passes )); then
            echo "Error: Exceeded maximum variable resolution depth for: $input" >&2
            exit 1
        fi

        local var_name="${BASH_REMATCH[1]}"
        if [ -z "${!var_name+x}" ]; then
            echo "Error: Variable '\${$var_name}' referenced in docker-compose.yml is not defined in .env" >&2
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
RAW_DEVICE_PATHS=$(grep -A 2 "device:" "$DOCKER_COMPOSE_FILE" | grep "device:" | awk '{print $2}')

# Check if we found any paths
if [ -z "$RAW_DEVICE_PATHS" ]; then
    echo "Error: No volume device paths found in docker-compose.yml"
    exit 1
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
    echo "✗ DEFAULT_STORAGE_FOLDER environment variable is not defined in .env"
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

# Set appropriate permissions
if chmod -R 777 "$BASE_DIR"; then
    echo "✓ Set permissions for $BASE_DIR"
else
    echo "✗ Failed to set permissions for $BASE_DIR"
    exit 1
fi

echo "✓ All required directories have been created successfully!"
echo "✓ You can now run 'docker-compose up -d' to start the Cre8or Docker services."
