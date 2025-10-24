#!/usr/bin/env bash
set -e

: "${REDIS_PRIMARY_PORT:=6379}"
: "${REDIS_SECONDARY_PORT:=6380}"
: "${REDIS_THIRD_PORT:=6381}"

if [ "${REDIS_CLUSTER_MODE:-false}" != "true" ]; then
    echo "🔹 REDIS_CLUSTER_MODE is not active, nothing will be done."
    exit 0
fi

# redis-cli command depending on REDIS_AUTHENTICATION
if [ "${REDIS_AUTHENTICATION:-false}" = "true" ]; then
    REDIS_CLI="docker exec -i ldds-redis redis-cli -a $REDIS_PASSWORD"
else
    REDIS_CLI="docker exec -i ldds-redis redis-cli"
fi

# Wait for primary node
echo "⏳ Waiting for the primary node ldds-redis to be ready..."
until $REDIS_CLI ping >/dev/null 2>&1; do
    sleep 1
done
echo "✔ Primary node is active"

# Get the network of the primary node
NETWORK=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}' ldds-redis)

# Start secondary nodes if they don't exist
for i in 2 3; do
    CONTAINER="ldds-redis-$i"
    PORT_VAR="REDIS_SECONDARY_PORT"
    if [ "$i" -eq 3 ]; then
        PORT_VAR="REDIS_THIRD_PORT"
    fi
    PORT=${!PORT_VAR}

    if ! docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER\$"; then
        echo "🚀 Starting $CONTAINER on port $PORT..."
        CMD="docker run -d --name $CONTAINER --network $NETWORK -p $PORT:6379 redis:7.4-alpine redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000 --appendonly yes"
        if [ "${REDIS_AUTHENTICATION:-false}" = "true" ]; then
            CMD="$CMD --requirepass $REDIS_PASSWORD"
        fi
        eval "$CMD"
    else
        echo "   ▸ Container $CONTAINER already exists, skipping..."
    fi
done

# Wait for secondary nodes
sleep 5
echo "⏳ Secondary nodes started, creating cluster..."

# Get Docker internal IPs of the nodes
REDIS_2_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ldds-redis-2)
REDIS_3_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ldds-redis-3)

NODE_LIST="ldds-redis:6379 $REDIS_2_IP:6379 $REDIS_3_IP:6379"

# Create cluster only if it doesn't exist
CLUSTER_STATE=$($REDIS_CLI cluster info 2>/dev/null | grep cluster_state | cut -d: -f2 | tr -d '\r' || echo "fail")
if [ "$CLUSTER_STATE" != "ok" ]; then
    echo "🔧 Creating Redis cluster with 3 nodes..."
    yes yes | $REDIS_CLI --cluster create $NODE_LIST --cluster-replicas 0
else
    echo "✔ Cluster already exists"
fi

sleep 10

# Show final status
$REDIS_CLI cluster nodes
$REDIS_CLI cluster info
echo "✅ Secondary nodes successfully added to the Redis cluster."
