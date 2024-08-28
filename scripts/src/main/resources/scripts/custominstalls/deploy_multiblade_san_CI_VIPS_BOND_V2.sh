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
#litp create -p /deployments/d1/clusters/c1 -t cluster


litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets='hb1,hb2' cluster_id="${cluster_id}"

#Add firewall to cluster
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

#litp create -p /deployments/d1/clusters/c1/services/PMmed -t clustered-service -o active=1 standby=1 name=PMmed


#litp create -p /deployments/d1/clusters/c1/services/SG1_id -t clustered-service -o active=1 standby=1 name=SG1
#litp create -p /deployments/d1/clusters/c1/services/SG2_id -t clustered-service -o active=1 standby=1 name=SG2
#litp create -p /deployments/d1/clusters/c1/services/SG3_id -t clustered-service -o active=1 standby=1 name=SG3

litp create -p /ms/services/cobbler -t cobbler-service

#Create storage 1 LVM
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

#Create storage 2 LVM
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_data
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1

#Create storage 3 VXVM
litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm -t volume-group -o volume_group_name=vg1_vxvm

litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm/file_systems/data1_vxvm -t file-system -o type=vxfs mount_point=/data2 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm/physical_devices/internal -t physical-device -o device_name=hd1

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=10G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=10G bootable=false uuid="${node_vxvm_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"

litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2
litp create -p /infrastructure/networking/networks/traffic1 -t network -o name='traffic1' subnet="${traffic_network1_subnet}"
litp create -p /infrastructure/networking/networks/traffic2 -t network -o name='traffic2' subnet="${traffic_network2_subnet}"
litp create -p /infrastructure/networking/networks/traffic3 -t network -o name='traffic3' subnet="${traffic_network3_subnet}"

litp inherit -p /ms/system -s /infrastructure/systems/sys1

##Update for bonding
#litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt

litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bondMgmt
litp create -p /ms/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bondMgmt

litp create -p /ms/network_interfaces/b0 -t bond -o device_name=bondMgmt ipaddress="${ms_ip}" network_name=mgmt

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

##Add new GW
litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet=${traffic_network1_gw_subnet} gateway=${traffic_network1_gw}
litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet=${traffic_network2_gw_subnet} gateway=${traffic_network2_gw}
litp create -p /infrastructure/networking/routes/traffic3_gw -t route -o subnet=${traffic_network3_gw_subnet} gateway=${traffic_network3_gw}


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s  /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1  
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/openjdk

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipaddress="${node_ip[$i]}" network_name=mgmt
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name='traffic1' ipaddress="${node_ip_2[$i]}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name='traffic2' ipaddress="${node_ip_3[$i]}" 
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" network_name='traffic3' ipaddress="${node_ip_4[$i]}"
    #update for bonding
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" master=bond0
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if7 -t eth -o device_name=eth7 macaddress="${node_eth7_mac[$i]}" master=bond0
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0 -t bond -o device_name=bond0 network_name='traffic3' ipaddress="${node_ip_4[$i]}"
   
    #Add firewalls
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config 

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=101 icmpipv6' proto=ipv6-icmp

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw
    #litp link -p /deployments/d1/clusters/c1/services/SG1_id/nodes/SG1_node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    #litp link -p /deployments/d1/clusters/c1/services/SG2_id/nodes/SG2_node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    #litp link -p /deployments/d1/clusters/c1/services/SG3_id/nodes/SG3_node$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
done

# Fallover service groups
FO_SG_pkg=(cups)
for (( x=0; x<${#FO_SG_pkg[@]}; x++ )); do
litp create -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}" -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs$(($x+1)) online_timeout=45 node_list='n1,n2'
litp create -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}" -t lsb-runtime -o name="${FO_SG_pkg[$x]}" service_name="${FO_SG_pkg[$x]}" 
litp create -p /software/items/"${FO_SG_pkg[$x]}" -t package -o name="${FO_SG_pkg[$x]}"
litp inherit -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${FO_SG_pkg[$x]}"
litp create  -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_fo1_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_fo1_vip2}" network_name=traffic3
done

# Add Parallel service groups
PL_SG_pkg=(ricci)
for (( x=0; x<${#PL_SG_pkg[@]}; x++ )); do
litp create -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}" -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs$(($x+1)) node_list='n1,n2'
litp create -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}" -t lsb-runtime -o name="${PL_SG_pkg[$x]}" service_name="${PL_SG_pkg[$x]}" 
litp create -p /software/items/"${PL_SG_pkg[$x]}" -t package -o name="${PL_SG_pkg[$x]}" 
litp inherit -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${PL_SG_pkg[$x]}"
litp create  -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_pl1_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_pl1_vip2}" network_name=traffic3
done


litp create_plan
