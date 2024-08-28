#!/bin/bash
#
# Sample LITP multi-blade deployment ('local disk' version)
#
# Usage:
#   deploy_multiblade_local.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /software/items/ntp1 -t ntp-service
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="${ntp_ip[1]}"
litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/c1 -t cluster
litp create -p /ms/services/cobbler -t cobbler-service -o boot_network=mgmt
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=16G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"
litp create -p /infrastructure/systems/sys1/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${ms_eth0_mac}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${node_eth0_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=40G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/ip_ranges/r1 -t ip-range -o network_name=mgmt start="${nodes_ip_start}" end="${nodes_ip_end}" subnet="${nodes_subnet}" gateway="${nodes_gateway}"

litp create -p /infrastructure/networking/network_profiles/np1 -t network-profile -o name=net-profile1 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np1/networks/mgmt -t network -o network_name=mgmt interface=nic0
litp create -p /infrastructure/networking/network_profiles/np1/interfaces/nic0 -t interface -o interface_basename=eth0

litp create -p /infrastructure/networking/network_profiles/np2 -t network-profile -o name=net-profile2 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np2/networks/mgmt -t network -o network_name=mgmt interface=nic0
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/nic0 -t interface -o interface_basename=eth0

litp link -p /ms/system -t blade -o system_name="${ms_sysname}"
litp link -p /ms/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${ms_ip}"
litp link -p /ms/network_profile -t network-profile -o name=net-profile1
litp link -p /ms/items/ntp -t ntp-service
litp update -p /ms -o hostname="$ms_host"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -t blade -o system_name="${node_sysname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -t os-profile -o name=os-profile1 
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${node_ip[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_profile -t network-profile -o name=net-profile2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -t storage-profile -o storage_profile_name=sp1
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -t ntp-service
done

litp create_plan
