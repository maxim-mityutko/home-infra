#!/usr/bin/env bash
#
# label-longhorn-nodes.sh
#
# Purpose:
#   Interactive helper for labeling Kubernetes nodes for Longhorn.
#
# What this script does:
#   1) Lists all nodes in the current Kubernetes cluster.
#   2) Asks which nodes should run Longhorn components.
#   3) For each selected node, prompts for a topology zone value.
#   4) Labels each selected node with:
#      - longhorn.io/node=true
#      - topology.kubernetes.io/zone=<selected value>
#
# Notes:
#   - Run from a shell with kubectl access to the cluster, typically on a
#     control-plane node.
#   - The topology value defaults to the selected node name.
#   - Labels are applied with --overwrite so the script can safely update an
#     existing value.

set -euo pipefail

readonly LONGHORN_NODE_LABEL="longhorn.io/node=true"
readonly TOPOLOGY_LABEL_KEY="topology.kubernetes.io/zone"

KUBECTL=""
ALL_NODES=()
SELECTED_NODES=()

log() {
  printf '%s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

detect_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    KUBECTL="kubectl"
    return
  fi

  if command -v microk8s.kubectl >/dev/null 2>&1; then
    KUBECTL="microk8s.kubectl"
    return
  fi

  die "Required command not found: kubectl or microk8s.kubectl"
}

load_nodes() {
  mapfile -t ALL_NODES < <("$KUBECTL" get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
  (( ${#ALL_NODES[@]} > 0 )) || die "No Kubernetes nodes found."
}

print_nodes() {
  local i

  log "Available Kubernetes nodes:"
  for i in "${!ALL_NODES[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "${ALL_NODES[$i]}"
  done
}

validate_label_value() {
  local value="$1"

  [[ ${#value} -le 63 ]] || return 1
  [[ "$value" =~ ^[A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?$ ]]
}

resolve_node_selection() {
  local selection="$1"
  local idx
  local node

  if [[ "$selection" =~ ^[0-9]+$ ]]; then
    idx=$((selection - 1))
    if (( idx >= 0 && idx < ${#ALL_NODES[@]} )); then
      printf '%s\n' "${ALL_NODES[$idx]}"
      return 0
    fi
    return 1
  fi

  for node in "${ALL_NODES[@]}"; do
    if [[ "$selection" == "$node" ]]; then
      printf '%s\n' "$node"
      return 0
    fi
  done

  return 1
}

prompt_longhorn_nodes() {
  local input
  local token
  local node
  local -A seen=()

  print_nodes

  while true; do
    SELECTED_NODES=()
    seen=()

    read -r -p "Select Longhorn nodes (numbers/names, comma or space separated; 'none' to skip): " input
    input="${input//,/ }"

    if [[ -z "$input" ]]; then
      log "At least one node selection is required, or enter 'none'."
      continue
    fi

    if [[ "$input" == "none" ]]; then
      log "Skipping Longhorn labels."
      exit 0
    fi

    if [[ "$input" == "all" ]]; then
      SELECTED_NODES=("${ALL_NODES[@]}")
      return
    fi

    for token in $input; do
      if ! node="$(resolve_node_selection "$token")"; then
        log "Invalid node selection: ${token}"
        SELECTED_NODES=()
        break
      fi

      if [[ -z "${seen[$node]:-}" ]]; then
        SELECTED_NODES+=("$node")
        seen[$node]=1
      fi
    done

    if (( ${#SELECTED_NODES[@]} > 0 )); then
      return
    fi
  done
}

prompt_topology_value() {
  local node="$1"
  local input

  while true; do
    read -r -p "Topology zone for ${node} [${node}]: " input
    input="${input:-$node}"

    if validate_label_value "$input"; then
      printf '%s\n' "$input"
      return
    fi

    log "Invalid label value. Use 63 characters or fewer, starting and ending with an alphanumeric character."
  done
}

apply_labels() {
  local node="$1"
  local topology_value="$2"

  log "Applying Longhorn labels to node ${node}..."
  "$KUBECTL" label node "$node" "$LONGHORN_NODE_LABEL" --overwrite
  "$KUBECTL" label node "$node" "${TOPOLOGY_LABEL_KEY}=${topology_value}" --overwrite
}

main() {
  detect_kubectl
  load_nodes
  prompt_longhorn_nodes

  local node
  local topology_value

  for node in "${SELECTED_NODES[@]}"; do
    topology_value="$(prompt_topology_value "$node")"
    apply_labels "$node" "$topology_value"
  done

  log "Longhorn labels applied successfully."
}

main "$@"
