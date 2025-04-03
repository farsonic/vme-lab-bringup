#!/bin/bash

# --- Configuration ---

BASE_IP="61.1.13"         # First 3 octets of IP
START_IP=11               # Starting last octet
GATEWAY="61.1.13.254"
INTERFACE="vlan.13"
DNS="8.8.8.8,8.8.4.4"
USERNAME="root"
PASSWORD="ubuntu"
UP_FLAG="-up"             # Remove if you don’t want to autostart VMs

VM_CREATE_SCRIPT="./vm-bringup.sh"  # Update if your script is in another path

# --- Usage ---
if [ -z "$1" ]; then
  echo "Usage: $0 <number-of-vms>"
  exit 1
fi

COUNT="$1"

# --- Create VMs ---
for i in $(seq 1 "$COUNT"); do
  VM_NAME="vm$i"
  LAST_OCTET=$((START_IP + i - 1))
  IP="${BASE_IP}.${LAST_OCTET}/24"

  echo "🚀 Creating $VM_NAME with IP $IP"

  "$VM_CREATE_SCRIPT" "$VM_NAME" "$IP" "$GATEWAY" "$INTERFACE" "$DNS" "$USERNAME" "$PASSWORD" "$UP_FLAG"
done

echo "✅ All $COUNT VM(s) created."
