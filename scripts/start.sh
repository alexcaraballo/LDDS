#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GENERATED_FILE="$BASE_DIR/docker-compose.yml"
SCRIPTS_DIR="$BASE_DIR/scripts"
SELECTED_SERVICES=("$@")

if [ ! -f "$GENERATED_FILE" ]; then
  echo "ERROR: $GENERATED_FILE does not exist. First generate the compose file with ./deploy.sh"
  exit 1
fi

echo "🚀 Starting services from $GENERATED_FILE"
docker compose -f "$GENERATED_FILE" up -d

# ===============================
# Redis Cluster: add secondary node
# ===============================
export REDIS_CLUSTER_MODE=${REDIS_CLUSTER_MODE:-false}
export REDIS_AUTHENTICATION=${REDIS_AUTHENTICATION:-false}
export REDIS_PASSWORD=${REDIS_PASSWORD:-lddsredispass}
export REDIS_PRIMARY_HOST=${REDIS_CLUSTER_HOST:-127.0.0.1}
export REDIS_PRIMARY_PORT=${REDIS_PORT:-6379}
export REDIS_SECONDARY_PORT=${REDIS_SECONDARY_PORT:-6380}
export REDIS_THIRD_PORT=${REDIS_THIRD_PORT:-6381}

echo "🔹 Configuring Redis Cluster:"

if [[ " ${SELECTED_SERVICES[*]:-} " =~ " redis " ]] && [ "$REDIS_CLUSTER_MODE" = "true" ]; then
  echo "🚀 REDIS_CLUSTER_MODE is active, starting secondary node and adding it to the cluster..."
  "$SCRIPTS_DIR/start_redis_cluster_node.sh"
fi
echo "✔ All services started successfully."