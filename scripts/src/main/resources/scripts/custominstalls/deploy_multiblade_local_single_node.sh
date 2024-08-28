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
function litp(){
    command litp "$@" 2>&1
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        exit 1
    fi
}

litpcrypt set key-for-root root "${nodes_ilo_password}"
#litpcrypt set key-for-sfs support support

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /software/items/ntp1 -t ntp-service
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names="ntpAlias1" address="${ntp_ip[1]}"
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="ntpAlias1"
litp create -p /deployments/d1 -t deployment
#litp create -p /deployments/d1/clusters/c1 -t cluster

litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets='hb1,hb2' cluster_id="${cluster_id}"

#Add firewall to cluster
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

litp create -p /ms/services/cobbler -t cobbler-service

#Create storage 1 LVM
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

#Create storage 2 VXVM
#litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver='vxvm'
#litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm -t volume-group -o volume_group_name=vg1_vxvm
#litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm/file_systems/data1_vxvm -t file-system -o type=vxfs mount_point=/data2 size=2G snap_size=100
#litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm/physical_devices/internal -t physical-device -o device_name=hd2

#Create 2nd vxvm disc
#litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg2_vxvm -t volume-group -o volume_group_name=vg2_vxvm
#litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg2_vxvm/file_systems/data2_vxvm -t file-system -o type=vxfs mount_point=/data3 size=100M snap_size=100
#litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg2_vxvm/physical_devices/internal -t physical-device -o device_name=hd3

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"

# Add IPv6 Default Route
litp create -p /infrastructure/networking/routes/default_ipv6 -t route6 -o subnet=::/0 gateway="${ipv6_gateway}"
###

litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2
litp create -p /infrastructure/networking/networks/traffic1 -t network -o name='traffic1' subnet="${traffic_network1_subnet}"
litp create -p /infrastructure/networking/networks/traffic2 -t network -o name='traffic2' subnet="${traffic_network2_subnet}"
litp create -p /infrastructure/networking/networks/traffic3 -t network -o name='traffic3' subnet="${traffic_network3_subnet}"


##ADD SFS
#litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1_init"
#litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1 -o export_path="${sfs_prefix}" provider="virtserv1" mount_point="/cluster1" mount_options="soft,intr" network_name="mgmt"

##ADD NFS
#litp create -t nfs-service -p /infrastructure/storage/storage_providers/sp1 -o name="nfs1_init" ipv4address="${nfs_management_ip}"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nfs_prefix}/ro_unmanaged" provider="nfs1_init" mount_point="/cluster_ro" mount_options="soft,intr" network_name="mgmt"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nfs_prefix}/rw_unmanaged" provider="nfs1_init" mount_point="/cluster_rw" mount_options="soft,intr" network_name="mgmt"

litp inherit -p /ms/system -s /infrastructure/systems/sys1

#Update for bonding
#litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bondmgmt
litp create -p /ms/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bondmgmt
litp create -p /ms/network_interfaces/b0 -t bond -o device_name=bondmgmt ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

#FIREWALL MS
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"
litp create -p /ms/configs/fw_config_init/rules/fw_icmpv6 -t firewall-rule -o name="099 icmpv6" proto="ipv6-icmp" provider=ip6tables

#litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
#litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp

##SYSCTRL PARAMS MS
litp create -p /ms/configs/mynodesysctl -t sysparam-node-config
litp create -p /ms/configs/mynodesysctl/params/sysctl_MS01 -t sysparam -o key=net.ipv4.udp_mem value="24794401 33059201 49588801"

##MOUNT NAS MS
#litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
#litp inherit -p /ms/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#litp inherit -p /ms/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2

##DNS MS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/init_name_server -o ipaddress=10.44.86.4 position=1

litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk

litp inherit -p /ms/items/java -s /software/items/openjdk

litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
#IPV6 Route
litp inherit -p /ms/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

litp inherit -p /ms/items/ntp -s /software/items/ntp1

litp update -p /ms -o hostname="$ms_host"

##Add new GW
#litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet=${traffic_network1_gw_subnet} gateway=${traffic_network1_gw}
litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet=${traffic_network2_gw_subnet} gateway=${traffic_network2_gw}
#traffic 3 gateway now done per node.
#litp create -p /infrastructure/networking/routes/traffic3_gw -t route -o subnet=${traffic_network3_gw_subnet} gateway=${traffic_network3_gw}


#litp inherit -p /deployments/d1/clusters/c1/storage_profile/vxvm_profile -s /infrastructure/storage/storage_profiles/profile_2 

##Attaching fencing disks
#litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid=${fencing_disk1_uuid} size=100M name=fencing_disk_1
#litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid=${fencing_disk2_uuid} size=100M name=fencing_disk_2
#litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid=${fencing_disk3_uuid} size=100M name=fencing_disk_3

##Adding network hosts
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh1 -o network_name="mgmt"     ip="172.16.101.10"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh2 -o network_name="mgmt"     ip="${ms_ip}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh3 -o network_name="mgmt"     ip="2001:ABCD:F0::10"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh4 -o network_name="traffic1" ip="${ms_ip}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh5 -o network_name="traffic1" ip="2001:ABCD:F0::10"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh6 -o network_name="traffic1" ip="172.16.101.11"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh7 -o network_name="traffic1" ip="2001:ABCD:F0::11"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh8 -o network_name="traffic2" ip="172.16.101.12"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh9 -o network_name="traffic2" ip="${ms_ipv6_00_noprefix}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh10 -o network_name="traffic2" ip="20.20.20.78"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh11 -o network_name="traffic1" ip="20.20.20.78"

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh12 -o network_name=traffic1 ip=${traffic_network1_gw}
##Note hardcoded to 2nd node IP
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh13 -o network_name=traffic1 ip="${node_ip_2[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh14 -o network_name=traffic2 ip=${traffic_network2_gw}
##Note hardcoded to 2nd node IP
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh15 -o network_name=traffic2 ip="${node_ip_3[1]}"



for (( i=0; i<${#node_sysname[@]}; i++ )); do
    ##create a gateway for each node service group
    litp create -p /infrastructure/networking/routes/traffic3_gw_n$(($i+1)) -t route -o subnet=${traffic_network3_gw_subnet} gateway="${node_ip_4[$i]}"

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s  /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1  
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/openjdk
    #Add bonding
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipv6address="${node_ipv6_00[$i]}" ipaddress="${node_ip[$i]}" network_name=mgmt
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" bridge='br0'
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6_00[$i]}" forwarding_delay=0 network_name='mgmt' stp=true forwarding_delay=30


####

    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" master=bondMgmt
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" master=bondMgmt
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bondMgmt -t bond -o device_name='bondMgmt' ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6_00[$i]}" network_name=mgmt

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name='traffic1' ipaddress="${node_ip_2[$i]}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name='traffic2' ipaddress="${node_ip_3[$i]}" 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" network_name='traffic3' ipaddress="${node_ip_4[$i]}"
    #Add firewalls
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config 

    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=099 icmpipv6' proto=ipv6-icmp

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
    ##IPV6 route
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n$(($i+1))

    ##ADD SFS
    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
    ##ADD NFS
    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2

    ###SYSCTRL NODES
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/init_config -t sysparam-node-config
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/init_config/params/sysctrl_01 -t sysparam -o key="net.ipv4.tcp_wmem" value="4096 65536 16777215"
	
    ##DNS 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.4 position=1
done


# Add Single Node service groups
PL_SG_pkg=(ricci)
for (( x=0; x<${#PL_SG_pkg[@]}; x++ )); do
litp create -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}" -t vcs-clustered-service -o active=1 standby=0 name=PL_vcs$(($x+1)) node_list='n1'
litp create -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}" -t lsb-runtime -o name="${PL_SG_pkg[$x]}" service_name="${PL_SG_pkg[$x]}" status_timeout=100
litp create -p /software/items/"${PL_SG_pkg[$x]}" -t package -o name="${PL_SG_pkg[$x]}" 
litp inherit -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${PL_SG_pkg[$x]}"
litp create  -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_fo1_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_fo1_vip2}" network_name=traffic3
done

litp create_plan
