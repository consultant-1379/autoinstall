#!/bin/bash
#
# Sample LITP multi-blade deployment ('local disk' version)
#
# Usage:
#   ST_Deployment_10.sh <CLUSTER_SPEC_FILE>
#
# VCS Cluster (VCS)
#
# TODO
# Sort aliases


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
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

 

litp create -p /infrastructure/networking/routes/r1 -t route -o name=default subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r2 -t route -o name=r2 subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r3 -t route -o name=r3 subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r4 -t route -o name=r4 subnet="${route4_subnet}" gateway="${nodes_gateway}"
#litp create -p /infrastructure/networking/routes/r5 -t route -o name=r5 subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -p /infrastructure/networking/routes/r5 -t route -o name=r5 subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2


# MS - 2 eth
litp link -p /ms/system -t blade -o system_name="${ms_sysname}"
litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip_ext}" network_name=data

litp link -p /ms/routes/r1 -t route -o name=default
litp link -p /ms/routes/r2 -t route -o name=r2
litp link -p /ms/routes/r3 -t route -o name=r3
litp link -p /ms/routes/r4 -t route -o name=r4
litp link -p /ms/routes/r5 -t route -o name=r5
litp update -p /ms -o hostname="$ms_host"


# Create nodes
# MNs interface - 4 eth 

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -t blade -o system_name="${node_sysname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -t os-profile -o name=os-profile1 

    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipaddress="${node_ip[$i]}" network_name=mgmt
    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" ipaddress="${node_ip_ext[$i]}" network_name=data
    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=heartbeat1
    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=heartbeat2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -t storage-profile -o storage_profile_name=sp1
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -t ntp-service -o name=ntp1
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -t route -o name=default
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2 -t route -o name=r2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r3 -t route -o name=r3
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r4 -t route -o name=r4
    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$[$i+1]

    # Creating Node Level Aliases
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config -t alias-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias -t alias -o alias_names="ms-alias" address="${ms_ip}"
    # Finished Creating Node Level Aliases

done

litp create -t ntp-service -p /software/items/ntp1 -o name=ntp1
litp link -t ntp-service -p /ms/items/ntp -o name=ntp1

for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t ntp-server -p /software/items/ntp1/servers/server"$i" -o server=${ntp_ip[$i+1]}
done


# SFS Filesystems and Shares
litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name="master" password="master" service_type="SFS"


if [ ${#node_sysname[@]} = 2 ]; then

    litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex1 -o name="ex1" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs1" export_options="secure,ro,no_root_squash"

else

    litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex1 -o name="ex1" allowed_clients="${node_ip[0]},${node_ip[1]},${node_ip[2]},${node_ip[3]}" prefix="${sfs_prefix}" file_system="fs1" export_options="secure,ro,no_root_squash"

fi

litp create -t nfs-virtual-server -p /infrastructure/storage/storage_providers/nfs_service/ip_addresses/vip -o name="vip" address="${sfs_vip}"
litp create -t nfs-file-system -p /infrastructure/storage/file_systems/fs1  -o name="fs1" network_name="mgmt" mount_point="/cluster1" mount_options="soft,intr"

litp link -t nfs-export -p  /infrastructure/storage/file_systems/fs1/export -o name="ex1"
litp link -t nfs-virtual-server -p  /infrastructure/storage/file_systems/fs1/vip -o name="vip"
litp link -t nfs-file-system -p /deployments/d1/clusters/c1/nodes/n1/file_systems/fs1 -o name="fs1"


# firewalls
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfsudp -o name="011 nfsudp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="udp"
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"


litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"

litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config/rules/fw_nfsudp -o name="011 nfsudp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="udp"
litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/fw_config/rules/fw_nfstcp -o name="001 nfstcp" dport="111,662,756,875,1110,2020,2049,4001,4045" proto="tcp"

litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config -o drop_all=falser


# 3 Fallover service groups
FO_SG_pkg=(cups postfix luci)
for (( x=0; x<${#FO_SG_pkg[@]}; x++ )); do
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}" -o active=1 standby=1 name=FO_vcs$(($x+1)) online_timeout=45
litp create -t lsb-runtime  -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}" -o name="${FO_SG_pkg[$x]}" service_name="${FO_SG_pkg[$x]}" cleanup_command=/opt/ericsson/cleanup_"${FO_SG_pkg[$x]}".sh
litp create -t package -p /software/items/"${FO_SG_pkg[$x]}" -o name="${FO_SG_pkg[$x]}"
litp link -t package -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}"/packages/pkg1 -o name="${FO_SG_pkg[$x]}"
        for (( i=0; i<${#node_sysname[@]}; i++ )); do
                litp link -t node -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/nodes/node$(($i+1)) -o hostname="${node_hostname[$i]}"
        done
done

# 2 Parallel service groups
PL_SG_pkg=(httpd ricci)
for (( x=0; x<${#PL_SG_pkg[@]}; x++ )); do
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}" -o active=2 standby=0 name=PL_vcs$(($x+1))
litp create -t lsb-runtime -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}" -o name="${PL_SG_pkg[$x]}" service_name="${PL_SG_pkg[$x]}" cleanup_command=/opt/ericsson/cleanup_"${PL_SG_pkg[$x]}".sh
litp create -t package -p /software/items/"${PL_SG_pkg[$x]}" -o name="${PL_SG_pkg[$x]}"
litp link -t package -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/runtimes/"${PL_SG_pkg[$x]}"/packages/pkg1 -o name="${PL_SG_pkg[$x]}"
        for (( i=0; i<${#node_sysname[@]}; i++ )); do
                litp link -t node -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/nodes/node$(($i+1)) -o hostname="${node_hostname[$i]}"
        done
done


litp create_plan
