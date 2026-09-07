#!/usr/bin/env bash
#
# 01-initial-node-setup.sh
#
# Purpose:
#   Interactive bootstrap script for a MicroK8s node on Ubuntu-based systems.
#
# What this script does:
#   1) Prompts for required network/user inputs:
#      - MAIN_IP (CIDR)
#      - MAIN_GW (IPv4 gateway)
#      - NAMESERVER_IP (IPv4 nameserver, defaults to MAIN_GW)
#      - Username to add to the microk8s group
#      - MicroK8s channel version
#      - Whether this is a Raspberry Pi install requiring cgroup memory flags
#      - Whether this is a Proxmox VM requiring qemu-guest-agent
#   2) Lists available network interfaces and prompts for:
#      - Main interface (required)
#      - Secondary interface (optional)
#        * If secondary is omitted, script assumes VLAN mode and asks for VLAN ID.
#   3) Updates system packages.
#   4) Writes /etc/netplan/50-cloud-init.yaml:
#      - Main interface is configured as static.
#      - Secondary interface is configured without addresses/nameservers using:
#          dhcp4: false
#          optional: true
#        (in VLAN mode this applies to the VLAN interface, in 2-NIC mode to
#        the selected secondary NIC).
#   5) Optionally enables cgroup memory flags.
#   6) Optionally installs qemu-guest-agent for Proxmox VMs.
#   7) Installs MicroK8s and common packages.
#   8) Disables automatic MicroK8s snap refreshes.
#   9) Configures user access, journald, and DNS resolver behavior.
#
# Notes:
#   - Run with sudo/root privileges.
#   - Netplan changes are written to disk by this script; reboot/apply as needed.
#   - Validate generated netplan before applying in production environments.

set -euo pipefail

readonly DEFAULT_MICROK8S_VERSION="1.35"
readonly DEFAULT_VLAN_ID="1"
readonly NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"

MAIN_IP=""
MAIN_GW=""
NAMESERVER_IP=""
USERNAME=""
MICROK8S_VERSION="$DEFAULT_MICROK8S_VERSION"
MAIN_IFACE=""
SETUP_MODE=""
SECONDARY_IFACE=""
VLAN_ID="$DEFAULT_VLAN_ID"
ENABLE_RPI_CGROUP_MEMORY="false"
IS_PROXMOX_VM="false"
AVAILABLE_IFACES=()

log() {
  printf '%s\n' "$1"
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

require_root() {
  if (( EUID != 0 )); then
    die "This script must be run with elevated privileges. Re-run it with sudo: sudo $0"
  fi
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: ${cmd}"
}

validate_cidr() {
  local cidr="$1"
  python3 - "$cidr" <<'PY'
import ipaddress
import sys

try:
    ipaddress.ip_interface(sys.argv[1])
except ValueError:
    print("invalid")
    sys.exit(1)
PY
}

validate_ipv4() {
  local ip="$1"
  python3 - "$ip" <<'PY'
import ipaddress
import sys

try:
    addr = ipaddress.ip_address(sys.argv[1])
    if addr.version != 4:
        raise ValueError("not IPv4")
except ValueError:
    print("invalid")
    sys.exit(1)
PY
}

prompt_main_ip() {
  local input
  while true; do
    read -r -p "Enter MAIN_IP in CIDR format (e.g. x.x.x.x/xx): " input
    [[ -z "$input" ]] && { log "MAIN_IP is required."; continue; }
    if validate_cidr "$input" >/dev/null 2>&1; then
      MAIN_IP="$input"
      return
    fi
    log "Invalid CIDR format. Expected x.x.x.x/xx."
  done
}

prompt_main_gw() {
  local input
  while true; do
    read -r -p "Enter MAIN_GW (IPv4 gateway): " input
    [[ -z "$input" ]] && { log "MAIN_GW is required."; continue; }
    if validate_ipv4 "$input" >/dev/null 2>&1; then
      MAIN_GW="$input"
      return
    fi
    log "Invalid IPv4 address."
  done
}

prompt_nameserver_ip() {
  local input
  while true; do
    read -r -p "Enter nameserver IPv4 address [${MAIN_GW}]: " input
    input="${input:-$MAIN_GW}"
    if validate_ipv4 "$input" >/dev/null 2>&1; then
      NAMESERVER_IP="$input"
      return
    fi
    log "Invalid IPv4 address."
  done
}

prompt_username() {
  local input
  while true; do
    read -r -p "Enter username to configure: " input
    [[ -z "$input" ]] && { log "Username cannot be empty."; continue; }
    USERNAME="$input"
    return
  done
}

prompt_microk8s_version() {
  local input
  read -r -p "Enter MicroK8s version [${DEFAULT_MICROK8S_VERSION}]: " input
  MICROK8S_VERSION="${input:-$DEFAULT_MICROK8S_VERSION}"
}

prompt_raspberry_pi_cgroup_memory() {
  local input
  read -r -p "Enable Raspberry Pi cgroup memory flags? This is only needed for Raspberry Pi installs. [y/N]: " input
  if [[ "$input" =~ ^[Yy]$ ]]; then
    ENABLE_RPI_CGROUP_MEMORY="true"
  fi
}

prompt_proxmox_vm() {
  local input
  read -r -p "Is this node running inside a Proxmox VM? [y/N]: " input
  if [[ "$input" =~ ^[Yy]$ ]]; then
    IS_PROXMOX_VM="true"
  fi
}

list_available_interfaces() {
  mapfile -t AVAILABLE_IFACES < <(ip -o link show | awk -F': ' '$2 != "lo" {split($2, a, "@"); print a[1]}' | sort -u)
  (( ${#AVAILABLE_IFACES[@]} > 0 )) || die "No non-loopback network interfaces found."
}

print_available_interfaces() {
  local i
  log "Available network interfaces:"
  for i in "${!AVAILABLE_IFACES[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "${AVAILABLE_IFACES[$i]}"
  done
}

resolve_interface_selection() {
  local selection="$1"
  local idx
  local iface

  if [[ "$selection" =~ ^[0-9]+$ ]]; then
    idx=$((selection - 1))
    if (( idx >= 0 && idx < ${#AVAILABLE_IFACES[@]} )); then
      printf '%s\n' "${AVAILABLE_IFACES[$idx]}"
      return 0
    fi
    return 1
  fi

  for iface in "${AVAILABLE_IFACES[@]}"; do
    if [[ "$selection" == "$iface" ]]; then
      printf '%s\n' "$iface"
      return 0
    fi
  done

  return 1
}

prompt_interface_settings() {
  local input
  local selected_iface

  list_available_interfaces
  print_available_interfaces

  while true; do
    read -r -p "Select main interface (name or number): " input
    [[ -z "$input" ]] && { log "Main interface is required."; continue; }
    if selected_iface="$(resolve_interface_selection "$input")"; then
      MAIN_IFACE="$selected_iface"
      break
    fi
    log "Invalid main interface selection."
  done

  while true; do
    read -r -p "Select secondary interface (name/number, skip for VLAN setup): " input
    if [[ -z "$input" ]]; then
      SETUP_MODE="vlan"
      break
    fi

    if selected_iface="$(resolve_interface_selection "$input")"; then
      if [[ "$selected_iface" == "$MAIN_IFACE" ]]; then
        log "Secondary interface must be different from main interface."
        continue
      fi
      SECONDARY_IFACE="$selected_iface"
      SETUP_MODE="two-nic"
      return
    fi

    log "Invalid secondary interface selection."
  done

  while true; do
    read -r -p "VLAN ID [${DEFAULT_VLAN_ID}]: " input
    VLAN_ID="${input:-$DEFAULT_VLAN_ID}"
    if [[ "$VLAN_ID" =~ ^[0-9]+$ ]] && (( VLAN_ID >= 1 && VLAN_ID <= 4094 )); then
      SECONDARY_IFACE="${MAIN_IFACE}.${VLAN_ID}"
      return
    fi
    log "VLAN ID must be an integer between 1 and 4094."
  done
}

print_summary() {
  log ""
  log "Starting setup with:"
  log "  Main IP      : ${MAIN_IP} via ${MAIN_GW}"
  log "  Nameserver   : ${NAMESERVER_IP}"
  log "  Main iface   : ${MAIN_IFACE}"
  if [[ "$SETUP_MODE" == "vlan" ]]; then
    log "  Secondary    : VLAN ${VLAN_ID} (${SECONDARY_IFACE}, no address)"
  else
    log "  Secondary    : NIC ${SECONDARY_IFACE} (no address)"
  fi
  log "  User         : ${USERNAME}"
  log "  MicroK8s ver : ${MICROK8S_VERSION}"
  log "  RPi cgroups : ${ENABLE_RPI_CGROUP_MEMORY}"
  log "  Proxmox VM   : ${IS_PROXMOX_VM}"
  log ""
}

confirm_continue() {
  local input
  read -r -p "Continue with setup? [y/N]: " input
  [[ "$input" =~ ^[Yy]$ ]] || die "Setup aborted."
}

write_netplan_config() {
  log "Configuring network interfaces in ${NETPLAN_FILE}..."

  if [[ "$SETUP_MODE" == "vlan" ]]; then
    cat <<EOF | sudo tee "$NETPLAN_FILE" >/dev/null
network:
  version: 2
  ethernets:
    ${MAIN_IFACE}:
      addresses:
        - ${MAIN_IP}
      nameservers:
        addresses:
          - ${NAMESERVER_IP}
      routes:
        - to: default
          via: ${MAIN_GW}
  vlans:
    ${SECONDARY_IFACE}:
      id: ${VLAN_ID}
      link: ${MAIN_IFACE}
      dhcp4: false
      optional: true
EOF
  else
    cat <<EOF | sudo tee "$NETPLAN_FILE" >/dev/null
network:
  version: 2
  ethernets:
    ${MAIN_IFACE}:
      addresses:
        - ${MAIN_IP}
      nameservers:
        addresses:
          - ${NAMESERVER_IP}
      routes:
        - to: default
          via: ${MAIN_GW}
    ${SECONDARY_IFACE}:
      dhcp4: false
      optional: true
EOF
  fi
}

configure_cgroup_memory() {
  local cmdline_file="/boot/firmware/cmdline.txt"

  if [[ "$ENABLE_RPI_CGROUP_MEMORY" != "true" ]]; then
    log "Skipping Raspberry Pi cgroup memory modification."
    return
  fi

  [[ -f "$cmdline_file" ]] || die "Raspberry Pi cmdline file not found: ${cmdline_file}"

  if ! grep -q "cgroup_enable=memory" "$cmdline_file"; then
    sudo sed -i 's/$/ cgroup_enable=memory cgroup_memory=1/' "$cmdline_file"
    log "cgroup memory flags added."
  else
    log "cgroup memory flags already present, skipping."
  fi
}

install_microk8s() {
  log "Installing MicroK8s v${MICROK8S_VERSION}..."
  sudo snap install microk8s --channel="${MICROK8S_VERSION}/stable" --classic
}

disable_microk8s_auto_refresh() {
  log "Disabling automatic MicroK8s snap refreshes..."
  sudo snap refresh --hold microk8s
}

update_system() {
  local packages=(nfs-common nano git btop)

  log "Updating system packages..."
  sudo apt update && sudo apt upgrade -y

  if [[ "$IS_PROXMOX_VM" == "true" ]]; then
    packages+=(qemu-guest-agent)
  fi

  log "Installing packages: ${packages[*]}..."
  sudo apt install -y "${packages[@]}"
}

configure_user_access() {
  getent passwd "$USERNAME" >/dev/null 2>&1 || die "User does not exist: ${USERNAME}"

  log "Creating alias for kubectl..."
  sudo snap alias microk8s.kubectl kubectl

  log "Adding user ${USERNAME} to microk8s group..."
  sudo mkdir -p "/home/${USERNAME}/.kube"
  sudo usermod -a -G microk8s "$USERNAME"
  sudo chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.kube"

  if [[ "${USER:-}" == "$USERNAME" ]]; then
    log "Current shell user matches configured user. Run 'newgrp microk8s' manually after script exits."
  fi
}

configure_logging() {
  log "Configuring journald to use volatile storage..."
  sudo sed -i 's/^#*Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
  sudo systemctl restart systemd-journald
}

configure_dns() {
  log "Disabling DNS stub listener..."
  sudo sed -r -i.orig 's/#?DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
  sudo rm -f /etc/resolv.conf
  sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
  sudo systemctl restart systemd-resolved
}

main() {
  require_root
  require_command sudo
  require_command python3
  require_command apt
  require_command snap
  require_command getent
  require_command ip
  require_command awk
  require_command sort

  prompt_main_ip
  prompt_main_gw
  prompt_nameserver_ip
  prompt_username
  prompt_microk8s_version
  prompt_raspberry_pi_cgroup_memory
  prompt_proxmox_vm
  prompt_interface_settings
  print_summary
  confirm_continue

  update_system
  write_netplan_config
  configure_cgroup_memory
  install_microk8s
  disable_microk8s_auto_refresh
  configure_user_access
  configure_logging
  configure_dns

  log ""
  log "All setup steps completed successfully."
  log "Please reboot the system to apply cgroup and network changes."
}

main "$@"
