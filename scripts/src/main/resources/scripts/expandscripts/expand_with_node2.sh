#!/bin/bash

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
litpcrypt set key-for-sfs support support

litp create -p /infrastructure/systems/sys3 -t blade -o system_name="${node_expansion_sysname[0]}"
litp create -p /infrastructure/systems/sys3/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_expansion_disk_uuid[0]}"
litp create -p /infrastructure/systems/sys3/disks/disk1 -t disk -o name=hd1 size=9G bootable=false uuid="${node_expansion_disk1_uuid[0]}"
litp create -p /infrastructure/systems/sys3/bmc -t bmc -o ipaddress="${node_expansion_bmc_ip[$i]}" username=root password_key=key-for-root

litp create -p /infrastructure/networking/routes/traffic3_gw_n2 -t route -o subnet=${traffic_network3_gw_subnet} gateway="${node_expansion_ip_4[0]}"

litp create -p /deployments/d1/clusters/c1/nodes/n2 -t node -o hostname="${node_expansion_hostname[0]}"

litp inherit -p /deployments/d1/clusters/c1/nodes/n2/system -s  /infrastructure/systems/sys3
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/os -s /software/profiles/os_prof1  
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/java -s /software/items/openjdk

litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_expansion_eth0_mac[0]}" bridge='br0'
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_expansion_ip[0]}" ipv6address="${node_expansion_ipv6_00[0]}" forwarding_delay=0 network_name='mgmt' stp=true forwarding_delay=30
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_expansion_eth2_mac[0]}" network_name=hb1
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_expansion_eth3_mac[0]}" network_name=hb2
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_expansion_eth4_mac[0]}" network_name='traffic1' ipaddress="${node_expansion_ip_2[0]}"
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_expansion_eth5_mac[0]}" network_name='traffic2' ipaddress="${node_expansion_ip_3[0]}" 
litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_expansion_eth6_mac[0]}" network_name='traffic3' ipaddress="${node_expansion_ip_4[0]}"

#Add firewalls
litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config_init -t firewall-node-config 
litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=099 icmpipv6' proto=ipv6-icmp

litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/r1 -s /infrastructure/networking/routes/r1

##IPV6 route
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n2

##ADD SFS
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1

##ADD NFS
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
