#!/bin/bash

usage() {
  echo "Usage: $0 <vm-name> <ip-address/cidr> <gateway> <interface> [dns1,dns2,...] <username> <password> [-up]"
  echo "Example: $0 vm1 61.1.12.11/24 61.1.12.254 vlan.10 8.8.8.8,8.8.4.4 ubuntu mypassword -up"
  exit 1
}

# Check for minimum number of args
if [ $# -lt 6 ]; then
  usage
fi

# Check for -up flag and strip it
UP_FLAG=false
ARGS=()
for arg in "$@"; do
  if [ "$arg" == "-up" ]; then
    UP_FLAG=true
  else
    ARGS+=("$arg")
  fi
done

# Reassign stripped args
set -- "${ARGS[@]}"

# Ensure remaining args are correct
if [ $# -lt 6 ]; then
  usage
fi

# Assign arguments
VM_NAME="$1"
IP_ADDR="$2"
GATEWAY="$3"
INTERFACE="$4"
shift 4

if [ $# -eq 3 ]; then
  DNS_SERVERS="$1"
  USERNAME="$2"
  PASSWORD="$3"
elif [ $# -eq 2 ]; then
  DNS_SERVERS="8.8.8.8,8.8.4.4"
  USERNAME="$1"
  PASSWORD="$2"
else
  usage
fi

# Paths
BASE_IMG="/var/lib/libvirt/images/master.img"
IMG_PATH="/var/lib/libvirt/images/${VM_NAME}.img"
TMP_CONF="/var/tmp/99-netcfg.yaml"
XML_PATH="./${VM_NAME}.xml"

# Check for base image
if [ ! -f "$BASE_IMG" ]; then
  echo "Error: Master image not found at $BASE_IMG"
  exit 1
fi

# Copy master image
cp "$BASE_IMG" "$IMG_PATH"

# Generate DNS list
DNS_YAML=$(echo "$DNS_SERVERS" | awk -F',' '{for(i=1;i<=NF;i++) printf "          - %s\n", $i}')

# Create Netplan config
cat <<EOF > "$TMP_CONF"
network:
  version: 2
  ethernets:
    enp0s2:
      dhcp4: no
      addresses:
        - $IP_ADDR
      gateway4: $GATEWAY
      nameservers:
        addresses:
$DNS_YAML
EOF

# Customize VM image
sudo virt-customize -q -a "$IMG_PATH" \
  --upload "$TMP_CONF":/etc/netplan/99-netcfg.yaml \
  --hostname "$VM_NAME" \
  --root-password "password:$PASSWORD" \
  --run-command "netplan apply"

# Clean up system identifiers
sudo virt-sysprep -q -a "$IMG_PATH"

# Remove temp file
rm "$TMP_CONF"

# Create domain XML
cat <<EOF > "$XML_PATH"
<domain type='kvm'>
  <name>${VM_NAME}</name>
  <memory unit='KiB'>4194304</memory>
  <vcpu placement='static'>2</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-2.9'>hvm</type>
    <boot dev='hd'/>
  </os>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${IMG_PATH}'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
    </disk>
    <interface type="direct">
      <source dev="${INTERFACE}" mode="private"/>
      <target dev="macvtap0"/>
      <model type="virtio"/>
    </interface>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
  </devices>
</domain>
EOF

echo "✅ VM image created and configured."
echo "✅ XML definition saved to $XML_PATH"

# If -up was provided, define and start the VM
if $UP_FLAG; then
  echo "🔁 Defining and starting VM..."
  sudo virsh define "$XML_PATH"
  sudo virsh start "$VM_NAME"
  echo "🚀 VM '$VM_NAME' has been started."
fi
