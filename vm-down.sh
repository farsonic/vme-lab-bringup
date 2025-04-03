#!/bin/bash

echo "🔍 Searching for VMs starting with 'vm'..."

# Get list of all VMs starting with 'vm'
VM_LIST=$(virsh list --all --name | grep -E '^vm[0-9]+')

if [ -z "$VM_LIST" ]; then
  echo "✅ No VMs found starting with 'vm'"
  exit 0
fi

# Destroy running VMs
for vm in $VM_LIST; do
  if virsh domstate "$vm" | grep -q running; then
    echo "🛑 Destroying running VM: $vm"
    sudo virsh destroy "$vm"
  fi
done

# Undefine all VMs
for vm in $VM_LIST; do
  echo "🧹 Undefining VM: $vm"
  sudo virsh undefine "$vm"
  sudo rm "$vm".xml

done

echo "✅ All matching VMs destroyed and undefined."
