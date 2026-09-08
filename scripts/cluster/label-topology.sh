#!/usr/bin/env bash
#
# label-topology.sh
#
# Purpose:
#   Interactively assign Kubernetes topology zone labels to cluster nodes.
#
# Existing labels are preserved as the default. Unlabelled nodes default to
# their node name. Override only when nodes share a physical failure domain
# (for example, the same hypervisor).

set -euo pipefail

readonly TOPOLOGY_LABEL_KEY="topology.kubernetes.io/zone"

KUBECTL=""
ALL_NODES=()
declare -A CURRENT_ZONES=()
SELECTED_NODES=()

log() {
  printf '%s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
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
  local node
  local zone

  while IFS=$'\t' read -r node zone; do
    ALL_NODES+=("$node")
    CURRENT_ZONES["$node"]="$zone"
  done < <("$KUBECTL" get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}{end}')

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

prompt_node_selection() {
  local input
  local token
  local node
  local -A seen=()

  print_nodes

  while true; do
    SELECTED_NODES=()
    seen=()

    read -r -p "Select nodes (numbers/names, comma or space separated; 'all' for every node): " input
    input="${input//,/ }"

    [[ -n "$input" ]] || {
      log "Select at least one node."
      continue
    }

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

    (( ${#SELECTED_NODES[@]} > 0 )) && return
  done
}

prompt_topology_value() {
  local node="$1"
  local input
  local default_zone="${CURRENT_ZONES[$node]:-$node}"

  while true; do
    read -r -p "Topology zone for ${node} [${default_zone}]: " input
    input="${input:-$default_zone}"

    if validate_label_value "$input"; then
      printf '%s\n' "$input"
      return
    fi

    log "Invalid label value. Use 63 characters or fewer, starting and ending with an alphanumeric character."
  done
}

apply_label() {
  local node="$1"
  local topology_value="$2"

  log "Applying ${TOPOLOGY_LABEL_KEY}=${topology_value} to ${node}..."
  "$KUBECTL" label node "$node" "${TOPOLOGY_LABEL_KEY}=${topology_value}" --overwrite
}

main() {
  detect_kubectl
  load_nodes
  prompt_node_selection

  local node
  local topology_value

  for node in "${SELECTED_NODES[@]}"; do
    topology_value="$(prompt_topology_value "$node")"
    apply_label "$node" "$topology_value"
  done

  log "Topology labels applied successfully."
}

main "$@"
