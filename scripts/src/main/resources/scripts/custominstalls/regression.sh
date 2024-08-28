#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   deploy_multiblade_san.sh <CLUSTER_SPEC_FILE>
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
litp create -p /software/items/ntp1 -t ntp-service -o name="ntp1"
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="${ntp_ip[1]}"
litp create -p /deployments/d1 -t deployment
#litp create -p /deployments/d1/clusters/c1 -t cluster

litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o type=sfha
#litp create -p /deployments/d1/clusters/c1/services/SG1_id -t clustered-service -o active=1 standby=1 name=SG1
#litp create -p /deployments/d1/clusters/c1/services/SG2_id -t clustered-service -o active=1 standby=1 name=SG2
#litp create -p /deployments/d1/clusters/c1/services/SG3_id -t clustered-service -o active=1 standby=1 name=SG3

litp create -p /ms/services/cobbler -t cobbler-service -o boot_network=mgmt
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_data
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"
litp create -p /infrastructure/systems/sys1/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${ms_eth0_mac}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${node_eth0_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_1 -t nic -o interface_name=eth1 macaddress="${node_eth1_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_2 -t nic -o interface_name=eth2 macaddress="${node_eth2_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_3 -t nic -o interface_name=eth3 macaddress="${node_eth3_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=10G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/routes/r1 -t route -o name="default" subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/ip_ranges/r1 -t ip-range -o network_name=mgmt start="${nodes_ip_start}" end="${nodes_ip_end}" subnet="${nodes_subnet}"

litp create -p /infrastructure/networking/network_profiles/np1 -t network-profile -o name=net-profile1 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np1/networks/mgmt -t network -o network_name=mgmt interface=nic0
litp create -p /infrastructure/networking/network_profiles/np1/interfaces/nic0 -t interface -o interface_basename=eth0
litp create -p /infrastructure/networking/network_profiles/np2 -t network-profile -o name=net-profile2 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np2/networks/mgmt -t network -o network_name=mgmt interface=nic0 vcs_lpr=true
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/nic0 -t interface -o interface_basename=eth0
litp create -p /infrastructure/networking/network_profiles/np2/networks/heartbeat1 -t network -o interface=nic2 network_name=hb1
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/nic2 -t interface -o interface_basename=eth2
litp create -p /infrastructure/networking/network_profiles/np2/networks/heartbeat2 -t network -o interface=nic3 network_name=hb2
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/nic3 -t interface -o interface_basename=eth3

litp link -p /ms/system -t blade -o system_name="${ms_sysname}"
litp link -p /ms/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${ms_ip}"
litp link -p /ms/network_profile -t network-profile -o name=net-profile1
litp link -p /ms/routes/r1 -t route -o name="default"
litp link -p /ms/items/ntp -t ntp-service -o name="ntp1"
litp update -p /ms -o hostname="$ms_host"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -t blade -o system_name="${node_sysname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -t os-profile -o name=os-profile1 
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${node_ip[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_profile -t network-profile -o name=net-profile2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -t storage-profile -o storage_profile_name=sp1
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -t ntp-service -o name="ntp1"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -t route -o name="default"
    #litp link -p /deployments/d1/clusters/c1/services/SG1_id/nodes/SG1_node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    #litp link -p /deployments/d1/clusters/c1/services/SG2_id/nodes/SG2_node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    #litp link -p /deployments/d1/clusters/c1/services/SG3_id/nodes/SG3_node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
done

litp link -t network -p /deployments/d1/clusters/c1/heartbeat_networks/hb1 -o network_name=hb1
litp link -t network -p /deployments/d1/clusters/c1/heartbeat_networks/hb2 -o network_name=hb2
litp link -t network -p /deployments/d1/clusters/c1/mgmt_network -o network_name=mgmt vcs_lpr=true

litp create_plan
