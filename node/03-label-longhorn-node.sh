#!/usr/bin/env bash
#
# 03-label-longhorn-node.sh
#
# Purpose:
#   Interactive helper for labeling the current Kubernetes node for Longhorn.
#
# What this script does:
#   1) Detects the current node name from the local hostname.
#   2) Asks whether the node should run Longhorn components.
#   3) If confirmed, labels the node with:
#      - longhorn.io/node=true
#      - topology.kubernetes.io/zone=<selected value>
#
# Notes:
#   - Run from a shell with kubectl access to the cluster.
#   - The topology value defaults to the current short hostname.
#   - Labels are applied with --overwrite so the script can safely update an
#     existing value.

set -euo pipefail

readonly LONGHORN_NODE_LABEL="longhorn.io/node=true"
readonly TOPOLOGY_LABEL_KEY="topology.kubernetes.io/zone"

KUBECTL=""
NODE_NAME=""
TOPOLOGY_VALUE=""

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

detect_node_name() {
  local short_hostname
  local full_hostname

  short_hostname="$(hostname -s)"
  full_hostname="$(hostname -f 2>/dev/null || true)"

  if "$KUBECTL" get node "$short_hostname" >/dev/null 2>&1; then
    NODE_NAME="$short_hostname"
    return
  fi

  if [[ -n "$full_hostname" ]] && "$KUBECTL" get node "$full_hostname" >/dev/null 2>&1; then
    NODE_NAME="$full_hostname"
    return
  fi

  die "Could not find a Kubernetes node matching hostname '${short_hostname}'."
}

validate_label_value() {
  local value="$1"

  [[ ${#value} -le 63 ]] || return 1
  [[ "$value" =~ ^[A-Za-z0-9]([-A-Za-z0-9_.]*[A-Za-z0-9])?$ ]]
}

confirm_longhorn_node() {
  local input

  read -r -p "Tag current node '${NODE_NAME}' as a Longhorn node? [y/N]: " input
  [[ "$input" =~ ^[Yy]$ ]]
}

prompt_topology_value() {
  local default_value
  local input

  default_value="$(hostname -s)"

  while true; do
    read -r -p "Topology zone value [${default_value}]: " input
    input="${input:-$default_value}"

    if validate_label_value "$input"; then
      TOPOLOGY_VALUE="$input"
      return
    fi

    log "Invalid label value. Use 63 characters or fewer, starting and ending with an alphanumeric character."
  done
}

apply_labels() {
  log "Applying Longhorn labels to node ${NODE_NAME}..."
  "$KUBECTL" label node "$NODE_NAME" "$LONGHORN_NODE_LABEL" --overwrite
  "$KUBECTL" label node "$NODE_NAME" "${TOPOLOGY_LABEL_KEY}=${TOPOLOGY_VALUE}" --overwrite
}

main() {
  require_command hostname
  detect_kubectl
  detect_node_name

  if ! confirm_longhorn_node; then
    log "Skipping Longhorn labels."
    exit 0
  fi

  prompt_topology_value
  apply_labels

  log "Longhorn labels applied successfully."
}

main "$@"
