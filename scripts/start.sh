#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
GENERATED_FILE="$BASE_DIR/docker-compose.yml"
if [ ! -f "$GENERATED_FILE" ]; then
  echo "ERROR: $GENERATED_FILE no existe. Genera el compose primero con ./deploy.sh"
  exit 1
fi
echo "🚀 Levantando servicios desde $GENERATED_FILE"
docker compose -f "$GENERATED_FILE" up -d
