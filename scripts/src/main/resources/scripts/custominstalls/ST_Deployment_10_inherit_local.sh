#!/bin/bash
#
# Sample LITP multi-blade deployment ('local disk' version)
#
# Usage:
#   ST_Deployment_10_inherit_local.sh <CLUSTER_SPEC_FILE>
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
litpcrypt set key-for-sfs support "${sfs_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment


# 1 VCS Cluster - VCS Type
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"

litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pv0 -t physical-device -o device_name=boot0


#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v1 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx1
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx/physical_devices/hd_vxvm -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx/file_systems/VXVM_FS_1 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_1 size=500M snap_size=100
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv1 -s /infrastructure/storage/storage_profiles/profile_v1


#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v2 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx2
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx/physical_devices/hd_vxvm -t physical-device -o device_name=hd2
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx/file_systems/VXVM_FS_2 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_2 size=500M snap_size=100
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv2 -s /infrastructure/storage/storage_profiles/profile_v2

#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v3 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx3
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx/physical_devices/hd_vxvm -t physical-device -o device_name=hd3
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx/file_systems/VXVM_FS_3 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_3 size=500M snap_size=100
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv3 -s /infrastructure/storage/storage_profiles/profile_v3

#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v4 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v4/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx4
litp create -p /infrastructure/storage/storage_profiles/profile_v4/volume_groups/vg_vmvx/physical_devices/hd_vxvm -t physical-device -o device_name=hd4
litp create -p /infrastructure/storage/storage_profiles/profile_v4/volume_groups/vg_vmvx/file_systems/VXVM_FS_4 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_4 size=500M snap_size=100
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv4 -s /infrastructure/storage/storage_profiles/profile_v4



litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/boot0 -t disk -o name=boot0 size=28G bootable=true uuid="${node_disk0_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${vxvm1_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=2G bootable=false uuid="${vxvm2_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3 size=2G bootable=false uuid="${vxvm3_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk4 -t disk -o name=hd4 size=2G bootable=false uuid="${vxvm4_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done


litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r2 -t route -o subnet="${route834_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r3 -t route -o subnet="${route836_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r4 -t route -o subnet="${route837_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
litp create -p /infrastructure/networking/routes/r6 -t route -o subnet="${route898_subnet}" gateway="${nodes_gateway}"

litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${route835_subnet}" litp_management=true # 835
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${route898_subnet}" # 898
litp create -t network -p /infrastructure/networking/networks/nfs -o name='nfs' subnet="${route836_subnet}" #836
litp create -t network -p /infrastructure/networking/networks/834 -o name='834' #834 ipv6 only

litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"
litp create -t network -p /infrastructure/networking/networks/ipv61 -o name=ipv61
litp create -t network -p /infrastructure/networking/networks/ipv62 -o name=ipv62

litp create -t ntp-service -p /software/items/ntp1

# MS - 4 eth - 2 bonds
# MS - 4 eth - 2 bonds
litp create -t bridge -p /ms/network_interfaces/br0 -o device_name=br0 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_835}" network_name=mgmt
litp create -t bridge -p /ms/network_interfaces/br834 -o device_name=br834 ipv6address="${ms_ipv6_834}" network_name=834 

litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bond0

litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}" master=bond1
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond1

litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' mode=1 miimon=100 bridge=br0
litp create -t vlan -p /ms/network_interfaces/bond0_834 -o device_name='bond0.834' bridge=br834

litp create -t bond -p /ms/network_interfaces/b1 -o device_name='bond1' ipaddress="${ms_ip_ext}" network_name=data mode=1 miimon=100

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route834_subnet}" gateway="${nodes_gateway}"
#litp inherit -p /ms/routes/r3 -s /infrastructure/networking/routes/r1 -o subnet="${route836_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route837_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
#litp inherit -p /ms/routes/r6 -s /infrastructure/networking/routes/r1 -o subnet="${route898_subnet}" gateway="${nodes_gateway}"

litp update -p /ms -o hostname="$ms_host_short"


# Create nodes
# MNs interface 

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br0 -o device_name=br0 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6[$i]}" network_name=mgmt    
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br898 -o device_name=br898 ipaddress="${node_ip_898[$i]}" ipv6address="${node_ipv6_898[$i]}" network_name=data    
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br836 -o device_name=br836 ipaddress="${node_ip_836[$i]}" ipv6address="${node_ipv6_836[$i]}" network_name='nfs'   
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br834 -o device_name=br834 ipv6address="${node_ipv6_834[$i]}" network_name='ipv61'   
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br837 -o device_name=br837 ipv6address="${node_ipv6_837[$i]}" network_name='ipv62' 

    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0 -o device_name='bond0' bridge=br0  mode=1 miimon=100


    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" master=bond0 
    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" master=bond0 


    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0_836  -o device_name='bond0.836' bridge=br836 

    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0_834  -o device_name='bond0.834' bridge=br834
 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0_837  -o device_name='bond0.837' bridge=br837 

    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" bridge=br898


    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route837_subnet}" gateway="${nodes_gateway}"

    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$[$i+1]

    # Creating Node Level Aliases
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config -t alias-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias -t alias -o alias_names="ms-alias" address="${ms_ip}"
    # Finished Creating Node Level Aliases

done

# HB and traffic networks - hardwired for 2 nodes
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[0]}" master=bond2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[0]}" master=bond2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[0]}" network_name=traffic2 ipaddress="${traf2_ip[0]}"


litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond2 -o device_name='bond2' mode=1 miimon=100 bridge=brtraffic1
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/brtraffic1 -o device_name=brtraffic1 network_name=traffic1 ipaddress="${traf1_ip[0]}" 


litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[1]}" master=bond2 
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[1]}" master=bond2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[1]}" network_name=traffic2 ipaddress="${traf2_ip[1]}"


litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond2 -o device_name='bond2' mode=1 miimon=100 bridge=brtraffic1
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/brtraffic1 -o device_name=brtraffic1 network_name=traffic1 ipaddress="${traf1_ip[1]}" 



for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t ntp-server -p /software/items/ntp1/servers/server"$i" -o server=${ntp_ip[$i+1]}
done


# SFS Filesystem
litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="10.44.86.231" user_name='support' password_key='key-for-sfs' pool_name="SFS_Pool"
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"

# FS managed
# Ideally this FS should be deleted from the SFS server before each install
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/exports/managed1 -o export_path="/vx/ST105-managed1" ipv4allowed_clients="10.44.86.105,10.44.86.106,10.44.86.107" export_options="rw,no_root_squash" size="1G"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/managed1 -o export_path="/vx/ST105-managed1" provider="virtserv1" mount_point="/SFSmanaged1" mount_options="soft" network_name="mgmt"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/managed1 -s /infrastructure/storage/nfs_mounts/managed1

# FS unmanaged
# This FS must already exist on the SFS server
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/unmanaged1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/SFSunmanaged1" mount_options="soft,intr" network_name="mgmt"

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1
litp inherit -p /ms/file_systems/sfs1 -s /infrastructure/storage/nfs_mounts/unmanaged1


# NFS 2 directory shares
litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service_sp1 -o name="nfs1" ipv4address="${nfs_management_ip}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nfs1 -o export_path="${nfs_prefix}/ro_unmanaged" provider="nfs1" mount_point="/nfs_cluster_ro" mount_options="soft,timeo=900,noexec,nosuid" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nfs2 -o export_path="${nfs_prefix}/rw_unmanaged" provider="nfs1" mount_point="/nfs_cluster_rw" mount_options="soft,timeo=900,noexec,nosuid" network_name="mgmt"

#Mount on MS and MNs
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/nfs1 -s /infrastructure/storage/nfs_mounts/nfs1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nfs1 -s /infrastructure/storage/nfs_mounts/nfs1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/nfs2 -s /infrastructure/storage/nfs_mounts/nfs2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/nfs2 -s /infrastructure/storage/nfs_mounts/nfs2

litp inherit -p /ms/file_systems/nfs1 -s /infrastructure/storage/nfs_mounts/nfs1
litp inherit -p /ms/file_systems/nfs2 -s /infrastructure/storage/nfs_mounts/nfs2


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

#open port 53 for dns
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_dnsudp -o 'name=071 dns' dport=53 proto=udp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_dnstcp -o 'name=072 dns' dport=53 proto=tcp

litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnsudp -o name="071 dns" dport=53 proto="udp"
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnstcp -o name="072 dns" dport=53 proto="tcp"

#open all ports on node2
litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config -o drop_all=false




# VCS Service Groups

# FAILOVER SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_cups -o active=1 standby=1 name=FO_SG1 online_timeout=300 node_list=n1,n2 dependency_list=""
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_luci -o active=1 standby=1 name=FO_SG2 online_timeout=300 node_list=n2,n1 dependency_list="SG_cups"


# PARALLEL SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_httpd -o active=2 standby=0 name=PAR_SG1 online_timeout=300 node_list="n2,n1" 
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_ricci -o active=2 standby=0 name=PAR_SG2 online_timeout=300 node_list="n2,n1" dependency_list="SG_cups,SG_luci"


# LSB Services

litp create -t service -p /software/services/cups -o service_name=cups 
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/applications/s1_cups -s /software/services/cups
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_cups/ha_configs/config -o status_interval=10 status_timeout=3600 restart_limit=0 startup_retry_limit=99999 


litp create -t service -p /software/services/luci -o service_name=luci 
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/applications/s1_cups -s /software/services/luci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_luci/ha_configs/config -o status_interval=3600 status_timeout=10 restart_limit=99999 startup_retry_limit=0 


litp create -t service -p /software/services/httpd -o service_name=httpd
litp inherit -p /deployments/d1/clusters/c1/services/SG_httpd/applications/s1_httpd -s /software/services/httpd
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_httpd/ha_configs/config -o status_interval=10 status_timeout=3600 restart_limit=1 startup_retry_limit=99999 


litp create -t service -p /software/services/ricci -o service_name=ricci
litp inherit -p /deployments/d1/clusters/c1/services/SG_ricci/applications/s1_ricci -s /software/services/ricci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_ricci/ha_configs/config -o status_interval=3600 status_timeout=10 restart_limit=99999 startup_retry_limit=1



#Create a SW Package
# RHEL 6.6 versions
litp create -t package -p /software/items/ricci -o name=ricci release=75.el6 version=0.16.2
litp inherit -p /software/services/ricci/packages/pkg1 -s /software/items/ricci

litp create -t package -p /software/items/httpd -o name=httpd release=39.el6 version=2.2.15
litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd

litp create -t package -p /software/items/luci -o name=luci release=63.el6 version=0.26.0
litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci

litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1
litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=67.el6 epoch=1
for (( i=0; i<2; i++ )); do

  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs -s /software/items/cups-libs

done


vip_count=1
ip_count=1
# Create IP Resources
# FO cups #VIPs = #AC(1)........ 1 IPv4 VIP per Traffic2 Network, 1 IPv4 + 1 IPv6 VIP per Traffic1 Network
for (( i=1; i<3; i++ )); do
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_cups/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_cups/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_cups/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
  vip_count=($vip_count+1)
  ip_count=$[$ip_count+1]
done

ip_count=1
# Create IP Resources
# FO luci #VIPs = #AC(1)........ 1 IPv4 VIP per Traffic2 Network, 1 IPv4 + 1 IPv6 VIP per Traffic1 Network
for (( i=1; i<3; i++ )); do
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_luci/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_luci/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_luci/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
  vip_count=($vip_count+1)
  ip_count=$[$ip_count+1]
done

ip_count=1
# Create IP Resources
# PAR httpd #VIPs = #AC(1)........ 1 IPv4 VIP per Traffic2 Network, 1 IPv4 + 1 IPv6 VIP per Traffic1 Network
for (( i=1; i<5; i++ )); do
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_httpd/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_httpd/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_httpd/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
  vip_count=($vip_count+1)
  ip_count=$[$ip_count+1]
done

ip_count=1
# Create IP Resources
# PAR ricci #VIPs = #AC(1)........ 1 IPv4 VIP per Traffic2 Network, 1 IPv4 + 1 IPv6 VIP per Traffic1 Network
for (( i=1; i<5; i++ )); do
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_ricci/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_ricci/ipaddresses/t1_ip$ip_count -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
  ip_count=$[$ip_count+1]
  litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_ricci/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
  vip_count=($vip_count+1)
  ip_count=$[$ip_count+1]
done



# Inherit filesystems 

# Mount VxVM Volume on cups (F/O)
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/spv3/volume_groups/vg_vmvx/file_systems/VXVM_FS_3

# Mount VxVM Volume on luci (F/O)
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/spv4/volume_groups/vg_vmvx/file_systems/VXVM_FS_4




# Network hosts
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh1 -o network_name=traffic1 ip="${traf1_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh2 -o network_name=traffic2 ip="${traf2_ip[0]}"

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh3 -o network_name=traffic1 ip="${traf1_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh4 -o network_name=traffic2 ip="${traf2_ip[1]}"

# network hosted by bonded vlan
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh5 -o network_name=nfs ip="${node_ip_836[0]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh6 -o network_name=nfs ip="${node_ipv6_836_nomask[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh7 -o network_name=nfs ip="${node_ip_836[1]}" 
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh8 -o network_name=nfs ip="${node_ipv6_836_nomask[1]}"


# Fencing disks
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid="${fen1_disk_uuid}" size=100M name=fencing_disk_1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid="${fen2_disk_uuid}" size=100M name=fencing_disk_2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid="${fen3_disk_uuid}" size=100M name=fencing_disk_3


# TODO - add Sysparams back in


#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=example105one.com,example105two.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_1 -o ipaddress=10.44.86.4 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_2 -o ipaddress=fdde:4d7e:d471::834:4:4 position=2

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=example105one.com,example105two.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_1 -o ipaddress=10.44.86.4 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_2 -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_3 -o ipaddress=fdde:4d7e:d471::834:4:4 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=example105one.com,example105two.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_1 -o ipaddress=10.44.86.4 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_2 -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_3 -o ipaddress=fdde:4d7e:d471::834:4:4 position=3


# IPV6 routes
litp create -t route6 -p /infrastructure/networking/routes/route6_default -o subnet=::/0 gateway=${ipv6_835_gateway}
litp create -t route6 -p /infrastructure/networking/routes/route6_1 -o subnet=${ipv6_834_subnet} gateway=${ipv6_834_gateway}

litp inherit -p /ms/routes/route6_default -s /infrastructure/networking/routes/route6_default
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route6_default -s /infrastructure/networking/routes/route6_default
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route6_default -s /infrastructure/networking/routes/route6_default


litp create_plan
