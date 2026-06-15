#!/usr/bin/env bash
#
# set-interface-altnames.sh
#
# Purpose:
#   Detect two network interfaces and assign persistent systemd altnames via
#   .link files:
#     1) Interface with IPv4 in user-provided subnet -> altname "forge"
#     2) Interface without global IPv4 address   -> altname "pub"
#
# Behavior:
#   - Excludes interface names matching EXCLUDE_REGEX
#   - Prompts for confirmation before writing files (unless --confirm is used)
#   - Writes:
#       /etc/systemd/network/10-forge.link
#       /etc/systemd/network/11-pub.link
#   - Reloads udev and triggers device add events so changes can apply
#     without reboot (when supported)
#
# Requirements:
#   - Run as root
#   - bash, iproute2 (ip), awk, grep, sed, python3, udevadm
#
# Usage:
#   sudo ./set-altnames.sh
#   sudo ./set-altnames.sh --subnet 192.168.42.0/25
#   sudo ./set-altnames.sh --confirm --subnet 192.168.42.0/25
#
# Exit behavior:
#   - Fails if no matching interface is found
#   - Fails if multiple candidates are found (to avoid wrong assignment)
#   - Exits safely if user declines confirmation
#
# Notes:
#   - This script defines "without IP" as "without global IPv4".
#   - For dual-stack environments, adjust selection logic if needed.
#   - If links are managed by cloud-init/NetworkManager, ensure no naming
#     policy conflicts with .link files.
#

set -euo pipefail

# Config
SUBNET=""
FORGE_ALT="forge"
PUB_ALT="pub"
FORGE_LINK_FILE="/etc/systemd/network/10-${FORGE_ALT}.link"
PUB_LINK_FILE="/etc/systemd/network/11-${PUB_ALT}.link"

# Exclude interface names matching this regex
# Example excludes: calico, flannel, cni, veth, loopback
EXCLUDE_REGEX='^(cali|flannel|cni|veth|lo)'

AUTO_CONFIRM=false

prompt_subnet() {
  local input

  if [[ -n "$SUBNET" ]]; then
    return
  fi

  if [[ "$AUTO_CONFIRM" == "true" ]]; then
    echo "--confirm requires --subnet (example: --subnet x.x.x.x/xx)." >&2
    exit 1
  fi

  read -r -p "Subnet for forge interface (e.g. x.x.x.x/xx): " input
  if [[ -z "${input}" ]]; then
    echo "Subnet is required. Provide --subnet or enter a value at the prompt." >&2
    exit 1
  fi

  SUBNET="$input"
}

usage() {
  cat <<EOF
Usage: $0 [--subnet CIDR] [--confirm]

Options:
  --subnet    Required subnet CIDR (example: x.x.x.x/xx)
  --confirm   Run non-interactively (requires --subnet)
  -h, --help  Show this help
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --subnet)
        if [[ $# -lt 2 || -z "${2:-}" || "${2:-}" == --* ]]; then
          echo "Missing value for --subnet (example: --subnet x.x.x.x/xx)." >&2
          usage >&2
          exit 1
        fi
        SUBNET="$2"
        shift 2
        ;;
      --subnet=*)
        SUBNET="${1#*=}"
        if [[ -z "$SUBNET" ]]; then
          echo "Missing value for --subnet (example: --subnet x.x.x.x/xx)." >&2
          usage >&2
          exit 1
        fi
        shift
        ;;
      --confirm)
        AUTO_CONFIRM=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

require_root() {
  if (( EUID != 0 )); then
    echo "ERROR: This script must be run with elevated privileges. Re-run it with sudo: sudo $0" >&2
    exit 1
  fi
}

is_excluded_iface() {
  local iface="$1"
  [[ "$iface" =~ $EXCLUDE_REGEX ]]
}

in_subnet() {
  local ip_cidr="$1"
  python3 - "$SUBNET" "$ip_cidr" <<'PY'
import ipaddress, sys
subnet = ipaddress.ip_network(sys.argv[1], strict=False)
iface_ip = ipaddress.ip_interface(sys.argv[2]).ip
print("yes" if iface_ip in subnet else "no")
PY
}

find_forge_iface() {
  local matches=()
  while read -r iface ipcidr; do
    [[ -z "${iface:-}" || -z "${ipcidr:-}" ]] && continue
    is_excluded_iface "$iface" && continue

    if [[ "$(in_subnet "$ipcidr")" == "yes" ]]; then
      matches+=("$iface")
    fi
  done < <(ip -o -4 addr show scope global | awk '{print $2, $4}')

  mapfile -t matches < <(printf "%s\n" "${matches[@]}" | sort -u)

  if [[ "${#matches[@]}" -eq 0 ]]; then
    echo "No interface has an IPv4 address in ${SUBNET} (after exclusions: ${EXCLUDE_REGEX})." >&2
    exit 1
  fi
  if [[ "${#matches[@]}" -gt 1 ]]; then
    echo "Multiple interfaces match ${SUBNET}: ${matches[*]}" >&2
    echo "Refine selection logic before writing .link files." >&2
    exit 1
  fi

  echo "${matches[0]}"
}

find_pub_iface() {
  local forge_iface="$1"
  local candidates=()

  while read -r iface; do
    [[ "$iface" == "$forge_iface" ]] && continue
    is_excluded_iface "$iface" && continue

    if ! ip -o -4 addr show dev "$iface" scope global | grep -q .; then
      candidates+=("$iface")
    fi
  done < <(ip -o link show | awk -F': ' '{print $2}' | cut -d'@' -f1)

  mapfile -t candidates < <(printf "%s\n" "${candidates[@]}" | sort -u)

  if [[ "${#candidates[@]}" -eq 0 ]]; then
    echo "No interface without global IPv4 found (excluding ${forge_iface}, regex ${EXCLUDE_REGEX})." >&2
    exit 1
  fi
  if [[ "${#candidates[@]}" -gt 1 ]]; then
    echo "Multiple interfaces without global IPv4 found: ${candidates[*]}" >&2
    echo "Refine selection logic before writing .link files." >&2
    exit 1
  fi

  echo "${candidates[0]}"
}

confirm_selection() {
  local forge_iface="$1"
  local pub_iface="$2"

  echo
  echo "Detected interface mapping:"
  echo "  ${forge_iface} -> altname ${FORGE_ALT} (IP in ${SUBNET})"
  echo "  ${pub_iface} -> altname ${PUB_ALT} (no global IPv4)"
  echo "  exclusions regex: ${EXCLUDE_REGEX}"
  echo

  if [[ "$AUTO_CONFIRM" == "true" ]]; then
    echo "--confirm set: proceeding without prompt."
    return
  fi

  read -r -p "Proceed and write .link files? [y/N]: " answer
  case "${answer}" in
    y|Y|yes|YES) ;;
    *)
      echo "Aborted by user."
      exit 0
      ;;
  esac
}

write_link_file() {
  local iface="$1"
  local altname="$2"
  local file="$3"

  cat > "$file" <<EOF
[Match]
OriginalName=${iface}

[Link]
AlternativeName=${altname}
EOF
}

apply_without_reboot() {
  local iface1="$1"
  local iface2="$2"

  udevadm control --reload
  udevadm trigger --action=add "/sys/class/net/${iface1}"
  udevadm trigger --action=add "/sys/class/net/${iface2}"
}

main() {
  parse_args "$@"
  require_root
  prompt_subnet

  local forge_iface
  local pub_iface

  forge_iface="$(find_forge_iface)"
  pub_iface="$(find_pub_iface "$forge_iface")"

  confirm_selection "$forge_iface" "$pub_iface"

  write_link_file "$forge_iface" "$FORGE_ALT" "$FORGE_LINK_FILE"
  write_link_file "$pub_iface" "$PUB_ALT" "$PUB_LINK_FILE"

  echo "Created:"
  echo "  ${FORGE_LINK_FILE}"
  echo "  ${PUB_LINK_FILE}"

  apply_without_reboot "$forge_iface" "$pub_iface"

  echo
  echo "Verification:"
  ip -d link show dev "$forge_iface"
  ip -d link show dev "$pub_iface"
}

main "$@"
