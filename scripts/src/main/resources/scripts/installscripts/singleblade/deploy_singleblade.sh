#!/bin/bash
#
# Sample LITP single-blade deployment
#
# Usage:
#   deploy_singleblade.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x
function litp(){
    command litp "$@" 2>&1
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        exit 1
    fi
}



litp create -p /software/profiles/rhel_6_4 -t os-profile -o name="sample-profile" path="/var/www/html/6/os/x86_64/"

sleep 7200

litp create -p /software/items/ntp1 -t ntp-service -o name="ntp1"
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="${ntp_ip[1]}"

litp create -p /infrastructure/systems/ms1 -t system -o system_name="MS"
#litp create -p /infrastructure/systems/ms1/network_interfaces/if0 -t nic -o interface_name="eth0" macaddress="$ms_eth0_mac"
#litp create -p /infrastructure/systems/ms1/network_interfaces/if1 -t nic -o interface_name="eth1" macaddress="$ms_eth1_mac"

litp create -p /infrastructure/system_providers/libvirt1 -t libvirt-provider -o name="libvirt1"

for (( i=0; i<${#node_eth1_mac[@]}; i++ )); do
    litp create -p /infrastructure/system_providers/libvirt1/systems/vm$(($i+1)) -t libvirt-system -o system_name="VM$(($i+1))"
    #litp create -p /infrastructure/system_providers/libvirt1/systems/vm$(($i+1))/network_interfaces/if0 -t nic -o interface_name="eth1" macaddress="${node_eth1_mac[$i]}"
    litp create -p /infrastructure/system_providers/libvirt1/systems/vm$(($i+1))/disks/disk0 -t disk -o name="sda" size="28G" bootable="true" uuid="ATA_QEMU_HARDDISK_QM00001"
done

litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name="sp1"
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name="vg_root"
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type="ext4" mount_point="/" size="8G"
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type="swap" mount_point="swap" size="2G"
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name="sda"


litp create -p /infrastructure/networking/routes/r1 -t route -o name="default" subnet="0.0.0.0/0" gateway="${ms_gateway}"
litp create -p /infrastructure/networking/routes/r2 -t route -o name="ms_default" subnet="0.0.0.0/0" gateway="${nodes_gateway}"
#litp create -p /infrastructure/networking/ip_ranges/range1 -t ip-range -o network_name="nodes" start="$nodes_ip_start" end="$nodes_ip_end" subnet="$nodes_subnet"
#litp create -p /infrastructure/networking/ip_ranges/range2 -t ip-range -o network_name="ms_external" start="$ms_ip" end="$ms_ip" subnet="$ms_subnet"

#litp create -p /infrastructure/networking/network_profiles/nodes -t network-profile -o name="node_profile" management_network="nodes"
#litp create -p /infrastructure/networking/network_profiles/nodes/networks/network0 -t network -o network_name="nodes" interface="if1"
#litp create -p /infrastructure/networking/network_profiles/nodes/interfaces/if1 -t interface -o interface_basename="eth1"

#litp create -p /infrastructure/networking/network_profiles/libvirt_provider -t network-profile -o name="libvirt_provider" management_network="nodes"
#litp create -p /infrastructure/networking/network_profiles/libvirt_provider/interfaces/if0 -t interface -o interface_basename="eth0"
#litp create -p /infrastructure/networking/network_profiles/libvirt_provider/interfaces/if1 -t interface -o interface_basename="eth1"

#litp create -p /infrastructure/networking/network_profiles/libvirt_provider/networks/network0 -t network -o network_name="nodes" bridge="br0"
#litp create -p /infrastructure/networking/network_profiles/libvirt_provider/bridges/br0 -t bridge -o stp="off" bridge_name="br0" interfaces="if1"
#litp create -p /infrastructure/networking/network_profiles/libvirt_provider/networks/network1 -t network -o network_name="ms_external" interface="if0"

#litp link -p /ms/ipaddresses/ip1 -t ip-range -o network_name="nodes" address="$nodes_gateway"
#litp link -p /ms/ipaddresses/ip2 -t ip-range -o network_name="ms_external" address="$ms_ip"
litp link -p /ms/system -t system -o system_name="MS"

litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=msext subnet="${ms_subnet}" 

litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" network_name=mgmt
litp create -p /ms/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip}" network_name=msext

litp create -p /ms/services/cobbler -t cobbler-service 

#litp link -p /ms/network_profile -t network-profile -o name="libvirt_provider"
litp link -p /ms/libvirt -t libvirt-provider -o name="libvirt1"
litp link -p /ms/routes/r1 -t route -o name="default"
litp link -p /ms/items/ntp -t ntp-service -o name="ntp1"
litp update -p /ms -o hostname="$ms_host"

litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/cluster1 -t cluster

for (( i=0; i<${#node_hostname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/system -t libvirt-system -o system_name="VM$(($i+1))"
    litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/os -t os-profile -o name="sample-profile"
    litp create -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" network_name=mgmt
    #litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/ipaddresses/ip1 -t ip-range -o network_name="nodes"
    #litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/network_profile -t network-profile -o name="node_profile"
    litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/storage_profile -t storage-profile -o storage_profile_name="sp1"
    litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/items/ntp1 -t ntp-service -o name="ntp1"
    litp link -p /deployments/d1/clusters/cluster1/nodes/node$(($i+1))/routes/r2 -t route -o name="ms_default"
done

litp create_plan
