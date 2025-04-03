# KVM Virtual Machine Automation Scripts

This repository provides simple Bash scripts to automate the creation, configuration, startup, shutdown, and cleanup of KVM virtual machines using libvirt and macvtap (macvlan) networking.

---

## 📁 Scripts Overview

### 1. vm-bringup.sh

Creates and configures a single VM based on a master image which you should have already downloaded and positioned into /var/lib/libvirt/images/ already. All my testing here is based on using issuing the following command

sudo wget -P /var/lib/libvirt/images/ https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img


*Features:*
- Copies a master image to create a new VM disk.
- Injects static IP network configuration using Netplan.
- Sets hostname, root password, and applies DNS.
- Optionally defines and starts the VM using -up.

*Usage:*

bash
./vm-bringup.sh <vm-name> <ip-address/cidr> <gateway> <interface> [dns1,dns2,...] <username> <password> [-up]


*Example:*

bash
./vm-bringup.sh vm1 61.1.12.11/24 61.1.12.254 vlan.10 8.8.8.8,8.8.4.4 ubuntu mypassword -up

If -up is provided, the VM will be auto-defined with virsh define and started with virsh start.

---

### 2. vm-down.sh

Destroys and undefines all VMs whose names start with vm.

*Usage:*

bash
./vm-down.sh


*Example Output:*

🛑 Destroying running VM: vm1
🧹 Undefining VM: vm1
🛑 Destroying running VM: vm2
🧹 Undefining VM: vm2
✅ All matching VMs destroyed and undefined.


---

### 3. vm-batch.sh

Creates multiple VMs in a loop by calling vm-bringup.sh.

*Features:*
- Auto-generates VM names like vm1, vm2, etc.
- Automatically assigns static IPs based on a base IP and increment.
- Optionally starts all VMs using the -up flag.

*Usage:*

bash
./vm-batch.sh <number-of-vms>


*Example:*

bash
./vm-batch.sh 3


Creates:
- vm1 → 61.1.12.11
- vm2 → 61.1.12.12
- vm3 → 61.1.12.13

> The script uses default values for gateway, DNS, username, password, and base image name. You can edit these at the top of vm-batch.sh.

---

## 📦 Requirements

- KVM + libvirt installed on host
- virt-customize and virt-sysprep from libguestfs
- A base image named master.img at /var/lib/libvirt/images/master.img
- VMs will be created at /var/lib/libvirt/images/vmX.img
- macvtap-compatible NIC interface (e.g. vlan.10)

---

## 🔧 Customization

You can modify:
- Base IP and subnet in vm-batch.sh
- Default username/password
- Network interface name (e.g., vlan.10)
- Memory/vCPU or XML template in vm-bringup.sh

---

## 🧹 Cleanup

To stop and undefine all vmX VMs: Note---> This will stop and delete any VM's that have a name that starts with "vm" !!!! 

bash
./vm-down.sh


---


- Cloud-init integration
