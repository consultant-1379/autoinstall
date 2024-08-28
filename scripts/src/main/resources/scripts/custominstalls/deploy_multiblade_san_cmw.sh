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
function litp(){
    command litp "$@" 2>&1
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        exit 1
    fi
}


litpcrypt set key-for-root root "${nodes_ilo_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /software/items/ntp1 -t ntp-service
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names="ntpAlias1" address="${ntp_ip[1]}"
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="ntpAlias1"
litp create -p /deployments/d1 -t deployment


litp create -p /deployments/d1/clusters/c1 -t cmw-cluster -o internal_network=mgmt tipc_networks='hb1,hb2' cluster_id="${cluster_id}"

#Add firewall to cluster
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"


litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_data
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=10G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"

litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2

litp inherit -p /ms/system -s /infrastructure/systems/sys1

litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt
#FIREWALL MS
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"
litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp

litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk

litp inherit -p /ms/items/java -s /software/items/openjdk

litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1

litp inherit -p /ms/items/ntp -s /software/items/ntp1

litp update -p /ms -o hostname="$ms_host"

litp create -t sfs-service -p /infrastructure/storage/storage_providers/sp1 -o name="nfs1"
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sp1/virtual_servers/vs1 -o name='vsvr1' ipv4address="10.44.86.231"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="/vx/Int248-int248" provider="vsvr1" mount_point="/cluster" mount_options="soft" network_name="mgmt"



for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o node_id=$[$i + 1] hostname="${node_hostname[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s  /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1  
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/openjdk

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipaddress="${node_ip[$i]}" network_name=mgmt
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
    #Add firewalls
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config 

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,662,756,875,2020,2049,4001,4045 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=101 icmpipv6' proto=ipv6-icmp

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1


litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
done

litp create_plan
