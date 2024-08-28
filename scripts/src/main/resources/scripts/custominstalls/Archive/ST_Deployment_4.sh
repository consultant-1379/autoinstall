#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_4.sh <CLUSTER_SPEC_FILE>
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
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=vcs low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"
#litp create -t clustered-service -p /deployments/d1/clusters/c1/services/PMmed -o active=1 standby=1 name=PMmed
litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_secondDisk
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/disk2FS1 -t file-system -o type=ext4 mount_point=/mp_disk2fs1 size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/disk2FS2 -t file-system -o type=ext4 mount_point=/mp_disk2fs2 size=1G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/disk2FS3 -t file-system -o type=ext4 mount_point=/mp_disk2fs3 size=1G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/disk2FS4 -t file-system -o type=ext4 mount_point=/mp_disk2fs4 size=1G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/disk2FS5 -t file-system -o type=ext4 mount_point=/mp_disk2fs5 size=1G

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# Add NTP alias with alias
litp create -t ntp-service -p /software/items/ntp1 -o name=ntp1
litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/routes/route1 -t route -o name=default subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/route2 -t route -o name=route2 subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/route3 -t route -o name=route3 subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/route4 -t route -o name=route4 subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/route5 -t route -o name=route5 subnet="${route_subnet_801}" gateway="${nodes_gateway}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2

litp link -p /ms/system -t blade -o system_name="${ms_sysname}"
litp link -p /ms/items/ntp -t ntp-service -o name=ntp1
litp link -p /ms/routes/route1 -t route -o name=default
litp link -p /ms/routes/route2 -t route -o name=route2
litp link -p /ms/routes/route3 -t route -o name=route3
litp link -p /ms/routes/route4 -t route -o name=route4
litp link -p /ms/routes/route5 -t route -o name=route5

litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip_ext}" network_name=data
litp update -p /ms -o hostname="${ms_host}"


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
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1 -t route -o name=default
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2 -t route -o name=route2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route3 -t route -o name=route3
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route4 -t route -o name=route4
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route5 -t route -o name=route5

done

litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="10.44.86.231"

litp create -t alias-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/fwServer -o alias_names="fwServer","dot30","ciNode" address="10.44.86.30"

litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name="master" password="master" service_type="SFS"

if [ ${#node_sysname[@]} = 2 ]; then

    litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex1 -o name="ex1" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs1" export_options="secure,ro,no_root_squash"

else

    litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex1 -o name="ex1" allowed_clients="${node_ip[0]},${node_ip[1]},${node_ip[2]},${node_ip[3]}" prefix="${sfs_prefix}" file_system="fs1" export_options="secure,ro,no_root_squash"

fi

litp create -t nfs-virtual-server -p /infrastructure/storage/storage_providers/nfs_service/ip_addresses/vip -o name="vip" address="${sfs_vip}"
litp create -t nfs-file-system -p /infrastructure/storage/file_systems/fs1  -o name="fs1" network_name="mgmt" mount_point="/storobs" mount_options="soft,intr"
litp link -t nfs-export -p  /infrastructure/storage/file_systems/fs1/export -o name="ex1"
litp link -t nfs-virtual-server -p  /infrastructure/storage/file_systems/fs1/vip -o name="vip"

litp link -t nfs-file-system -p /deployments/d1/clusters/c1/nodes/n1/file_systems/fs1 -o name="fs1"
litp link -t nfs-file-system -p /deployments/d1/clusters/c1/nodes/n2/file_systems/fs1 -o name="fs1"

litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,1110,2049,4045 proto=udp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,1110,2049,4045 proto=tcp

for (( i=0; i<${#node_sysname[@]}; i++ )); do
        litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
        litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
	litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,1110,2049,4045 proto=udp
	litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,1110,2049,4045 proto=tcp
done

# Fallover service groups
FO_SG_pkg=(cups postfix)
for (( x=0; x<${#FO_SG_pkg[@]}; x++ )); do
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}" -o active=1 standby=1 name=FO_vcs$(($x+1)) online_timeout=45
litp create -t lsb-runtime  -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}" -o name="${FO_SG_pkg[$x]}" service_name="${FO_SG_pkg[$x]}" cleanup_command=/opt/ericsson/cleanup_"${FO_SG_pkg[$x]}".sh
litp create -t package -p /software/items/"${FO_SG_pkg[$x]}" -o name="${FO_SG_pkg[$x]}"
litp link -t package -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}"/packages/pkg1 -o name="${FO_SG_pkg[$x]}"
        for (( i=0; i<${#node_sysname[@]}; i++ )); do
                litp link -t node -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/nodes/node$(($i+1)) -o hostname="${node_hostname[$i]}"
        done
done
# Add Parallel service groups
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
