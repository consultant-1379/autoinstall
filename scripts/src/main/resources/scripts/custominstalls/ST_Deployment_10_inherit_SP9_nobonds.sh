#!/bin/bash
#
# Sample LITP multi-blade deployment ('remote disk' version)
#
# Usage:
#   ST_Deployment_10_inherit.sh <CLUSTER_SPEC_FILE>
#
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
litp create -p /deployments/d1 -t deployment


# 1 VCS Cluster - VCS Type
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"

litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vmvx/physical_devices/hd1_vxvm -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vmvx/file_systems/VG2_FS_1 -t file-system -o type=vxfs mount_point=/mp_VG2_FS1 size=500M snap_size=100
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${vxvm_disk_uuid[0]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done


litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r2 -t route -o subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r3 -t route -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r4 -t route -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
#litp create -p /infrastructure/networking/routes/r5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -p /infrastructure/networking/routes/r5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/backup -o name='backup' subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/nfs -o name='nfs' subnet="${route3_subnet}"
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"

litp create -t ntp-service -p /software/items/ntp1

# MS 
litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" ipv6address="${ms_ipv6}" network_name=mgmt

litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}" ipaddress="${ms_ip_ext}" network_name=data 



litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r3 -s /infrastructure/networking/routes/r1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"

litp update -p /ms -o hostname="$ms_host_short"


# Create nodes
# MNs interface 

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6[$i]}" network_name=mgmt 

    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" ipaddress="${node_ip_ext[$i]}" network_name=data

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}"
 #   litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r3 -s /infrastructure/networking/routes/r1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r8 -s /infrastructure/networking/routes/r1 -o subnet="${route3_subnet}" gateway="${node_ip[$i]}"

    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$[$i+1]

    # Creating Node Level Aliases
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config -t alias-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias -t alias -o alias_names="ms-alias" address="${ms_ip}"
    # Finished Creating Node Level Aliases

done

# HB and traffic networks - hardwired for 2 nodes
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[0]}" network_name=traffic1 ipaddress="${traf1_ip[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[0]}" network_name=traffic2 ipaddress="${traf2_ip[0]}"



litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[1]}" network_name=traffic1 ipaddress="${traf1_ip[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[1]}" network_name=traffic2 ipaddress="${traf2_ip[1]}"




for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t ntp-server -p /software/items/ntp1/servers/server"$i" -o server=${ntp_ip[$i+1]}
done




# firewalls
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfsudp -o name="011 nfsudp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="udp"
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfstcp -o name="001 nfstcp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="tcp"
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"


litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfstcp -o name="001 nfstcp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="tcp"

litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config/rules/fw_nfsudp -o name="011 nfsudp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="udp"
litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables

litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config -o drop_all=false

# Service Groups
# 3 F/O SGs - 1st SG #VIP=2x#AC 2nd SG  #VIP=2x#AC  3rd SG  #VIP=2x#AC
# 2 PL  SGs - 4th SG #VIP=2x#AC 5th SG  #VIP=2x#AC
x=0
SG_pkg[x]="cups";       SG_VIP_count[x]=2;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=10	status_timeout[x]=3600	restart_limit[x]=0	startup_retry_limit[x]=99999 version[x]=1.4.2 release[x]=50.el6_4.5	x=$[$x+1]
SG_pkg[x]="luci";       SG_VIP_count[x]=2;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=3600	status_timeout[x]=10	restart_limit[x]=99999	startup_retry_limit[x]=0 version[x]=0.26.0 release[x]=37.el6	x=$[$x+1]
SG_pkg[x]="dovecot";       SG_VIP_count[x]=2;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=3600	status_timeout[x]=10	restart_limit[x]=99999	startup_retry_limit[x]=0 version[x]=2.0.9 release[x]=5.el6	x=$[$x+1]
SG_pkg[x]="httpd";      SG_VIP_count[x]=$[2*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=10	status_timeout[x]=3600	restart_limit[x]=1	startup_retry_limit[x]=99999 version[x]=2.2.15 release[x]=29.el6_4	x=$[$x+1]
SG_pkg[x]="ricci";      SG_VIP_count[x]=$[2*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=3600	status_timeout[x]=10	restart_limit[x]=99999	startup_retry_limit[x]=1 version[x]=0.16.2 release[x]=63.el6	x=$[$x+1]


vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
ip_count=1
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" 
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs$(($x+1)) online_timeout=300 node_list='n1,n2'
litp create -t lsb-runtime           -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}" status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}" #cleanup_command=/opt/ericsson/cleanup_"${SG_pkg[$x]}".sh
litp inherit                         -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
        for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
                ip_count=$[$ip_count+1]
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
                vip_count=($vip_count+1)
                ip_count=$[$ip_count+1]
        done
done


litp create_plan
