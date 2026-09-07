#!/bin/bash
set -e

# Script to label Kubernetes nodes with topology.kubernetes.io/zone
# Based on the pattern from label-longhorn-nodes.sh

# Define node-to-zone mapping
# Format: ["node-name"]="zone-name"
declare -A NODE_ZONES=(
  ["node-1"]="zone-a"
  ["node-2"]="zone-b"
  ["node-3"]="zone-c"
)

echo "Labeling nodes with topology zones..."

for NODE in "${!NODE_ZONES[@]}"; do
  ZONE=${NODE_ZONES[$NODE]}
  echo "Setting topology.kubernetes.io/zone=$ZONE on $NODE"
  kubectl label node "$NODE" "topology.kubernetes.io/zone=$ZONE" --overwrite
done

echo "Node labeling complete."
