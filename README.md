Simple Bash scripts to automate the creation, configuration, startup, shutdown, and cleanup of KVM virtual machines using libvirt and macvtap (macvlan) networking.

---

### 1. vm-bringup.sh

Creates and configures a single VM based on a master image which you should have already downloaded and positioned into /var/lib/libvirt/images/ already. All my testing here is based on using a specific ubuntu cloud image. Yes, I could use cloud-init here but this just quick for testing. 

```
sudo wget -P /var/lib/libvirt/images/ https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img
mv /var/lib/libvirt/images/ubuntu-20.04-server-cloudimg-amd64-disk-kvm.img /var/lib/libvirt/images/master.img
```

Also, you will need to have the VLAN sub-interface defined on a physical interface. So, for example I have an interface called bond1 then I create a new vlan interface using the following command. The underlying physical interface will need to be 'Up' and connected to a switch port that is configured as a trunk. 

```
ip link add link bond1 vlan.13 type vlan id 13
ip link set up dev vlan.13
```

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
```
./vm-bringup.sh vm1 10.0.12.11/24 10.0.12.254 vlan.10 8.8.8.8,8.8.4.4 ubuntu mypassword -up
```

If -up is provided, the VM will be auto-defined with virsh define and started with virsh start.

---

### 2. vm-down.sh

Destroys and undefines all VMs whose names start with vm.

*Usage:*

bash
```
./vm-down.sh
```

---

### 3. vm-bulk.sh

Creates multiple VMs in a loop by calling vm-bringup.sh.

*Features:*
- Auto-generates VM names like vm1, vm2, etc.
- Automatically assigns static IPs based on a base IP and increment.
- Optionally starts all VMs using the -up flag.

*Usage:*

bash
```
./vm-bulk.sh <number-of-vms>
```

*Example:*

bash
./vm-bulk.sh 3


Creates:
- vm1 → 10.0.12.11
- vm2 → 10.0.12.12
- vm3 → 10.0.12.13

> The script uses default values for gateway, DNS, username, password, and base image name. You can edit these at the top of vm-bulk.sh.

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
- Base IP and subnet in vm-bulk.sh
- Default username/password (I typically set the root user for quick testing) 
- Network interface name (e.g., vlan.10)
- Memory/vCPU or XML template in vm-bringup.sh
---

