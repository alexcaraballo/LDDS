#!/usr/bin/env bash
# Simple helper: iterate over stacks/* and run docker compose up -d in each
set -euo pipefail
base_dir="$(cd "$(dirname "$0")" && pwd)"
stacks_dir="$base_dir/stacks"
if [ ! -d "$stacks_dir" ]; then
  echo "No stacks directory found at $stacks_dir"
  exit 0
fi
for d in "$stacks_dir"/*/; do
  [ -d "$d" ] || continue
  echo "Deploying stack in $d"
  (cd "$d" && docker compose up -d)
done
echo "All stacks deployed."
