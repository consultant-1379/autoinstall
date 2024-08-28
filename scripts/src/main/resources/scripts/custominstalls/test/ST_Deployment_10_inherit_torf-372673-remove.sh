#!/bin/bash
#
# Sample LITP multi-blade deployment ('remote disk' version)
#
# Usage:
#   ST_Deployment_10_inherit.sh <CLUSTER_SPEC_FILE>
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

litp import /tmp/test_service_name-2.0-1.noarch.rpm 3pp

# run script to install snaptag Plugins
# also creates dir /var/www/html/REPO1
# expect /tmp/snaptaginstall_expect_script.exp

# run script to creates dir /var/www/html/REPO1
 expect /tmp/mkdir.repo.exp

# Install plugin for LITPCDS-10650 - config task replacement plugin
expect /tmp/root_run_script.exp "${ms_host_short}" /tmp/litpcds10650_plugin_install.sh

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# TORF-372673 ensure elasticsearch is installed when rsyslog is not
yum remove -y rsyslog

# 1 VCS Cluster - VCS Type
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}" critical_service="SG_cups" vcs_seed_threshold=2

litp create -p /ms/services/cobbler -t cobbler-service -o pxe_boot_timeout=601
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/fs1 -t file-system -o type="ext4" mount_point="/nested1/data_dir1" size="200M" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/fs2 -t file-system -o type="ext4"  size="200M" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pv0 -t physical-device -o device_name=boot0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pv1 -t physical-device -o device_name=boot1

#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v1 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx1
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx/physical_devices/hda_vxvm -t physical-device -o device_name=hd1a
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx/physical_devices/hdb_vxvm -t physical-device -o device_name=hd1b
litp create -p /infrastructure/storage/storage_profiles/profile_v1/volume_groups/vg_vmvx/file_systems/VXVM_FS_1 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_1 size=500M snap_size=0 backup_snap_size=0
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv1 -s /infrastructure/storage/storage_profiles/profile_v1


#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v2 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx2
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx/physical_devices/hda_vxvm -t physical-device -o device_name=hd2a
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx/physical_devices/hdb_vxvm -t physical-device -o device_name=hd2b
litp create -p /infrastructure/storage/storage_profiles/profile_v2/volume_groups/vg_vmvx/file_systems/VXVM_FS_2 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_2 size=500M snap_size=3 backup_snap_size=3
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv2 -s /infrastructure/storage/storage_profiles/profile_v2

#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v3 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx3
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx/physical_devices/hda_vxvm -t physical-device -o device_name=hd3a
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx/physical_devices/hdb_vxvm -t physical-device -o device_name=hd3b
litp create -p /infrastructure/storage/storage_profiles/profile_v3/volume_groups/vg_vmvx/file_systems/VXVM_FS_3 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_3 size=500M snap_size=50 backup_snap_size=100
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv3 -s /infrastructure/storage/storage_profiles/profile_v3

#VxVM
litp create -p /infrastructure/storage/storage_profiles/profile_v4 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_v4/volume_groups/vg_vmvx -t volume-group -o volume_group_name=vg_vmvx4
litp create -p /infrastructure/storage/storage_profiles/profile_v4/volume_groups/vg_vmvx/physical_devices/hd_vxvm -t physical-device -o device_name=hd4
litp create -p /infrastructure/storage/storage_profiles/profile_v4/volume_groups/vg_vmvx/file_systems/VXVM_FS_4 -t file-system -o type=vxfs mount_point=/mp_VXVM_FS_4 size=500M snap_size=100 backup_snap_size=50
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/spv4 -s /infrastructure/storage/storage_profiles/profile_v4

# Model LVM on MS
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/spms
litp create -t volume-group -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1 -o volume_group_name="vg_root"
# Model LVM on KS (except software - added in soak)
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/var -o type="ext4" mount_point="/var" size="15G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/varlog -o type="ext4" mount_point="/var/log" size="20G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/varwww -o type="ext4" mount_point="/var/www" size="70G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/home -o type="ext4" mount_point="/home" size="6G" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/root -o type="ext4" mount_point="/" size="15G" snap_size="5" backup_snap_size="10" snap_external="false"
# Add extra LVM
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/fs1 -o type="ext4" mount_point="/nested1/data_dir1" size="200M" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/fs2 -o type="ext4" mount_point="/nested2/nested3/data_dir2" size="200M" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t file-system -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/file_systems/fs3 -o type="ext4" size="200M" snap_size="5" backup_snap_size="10" snap_external="false"
litp create -t physical-device -p /infrastructure/storage/storage_profiles/spms/volume_groups/vg1/physical_devices/pd1 -o device_name="hdms1"

litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/spms

# DISKS
litp create -t disk -p /infrastructure/systems/sys1/disks/d1 -o name="hdms1" size="550G" bootable="true" uuid="${ms1_disk_uuid}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/boot0 -t disk -o name=boot0 size=28G bootable=true uuid="${node_disk0_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/boot1 -t disk -o name=boot1 size=10M bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1a size=20G bootable=false uuid="${vxvm1_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2a size=2G bootable=false uuid="${vxvm2_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3a size=2G bootable=false uuid="${vxvm3_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk4 -t disk -o name=hd4 size=2G bootable=false uuid="${vxvm4_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk5 -t disk -o name=hd1b size=2G bootable=false uuid="${vxvm5_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk6 -t disk -o name=hd2b size=2G bootable=false uuid="${vxvm6_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk7 -t disk -o name=hd3b size=2G bootable=false uuid="${vxvm7_disk_uuid}"
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

# private networks
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="$net1vm_subnet"
litp create -t network -p /infrastructure/networking/networks/net2vm -o name=net2vm subnet="$net2vm_subnet"
litp create -t network -p /infrastructure/networking/networks/net3vm -o name=net3vm subnet="$net3vm_subnet"
litp create -t network -p /infrastructure/networking/networks/net4vm -o name=net4vm subnet="$net4vm_subnet"

litp create -t ntp-service -p /software/items/ntp1
litp create -t ntp-service -p /software/items/ntp2
litp create -t ntp-service -p /software/items/ntp3

# MS - 4 eth - 2 bonds
# MS - 4 eth - 2 bonds


litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bond0
litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' mode=1 bridge=br0 arp_interval=2000 arp_validate=backup arp_all_targets=any arp_ip_target="10.44.86.65,10.44.86.106,10.44.86.107,10.44.86.108"

litp create -t bridge -p /ms/network_interfaces/br0 -o device_name=br0 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_835}" network_name=mgmt multicast_snooping=1 multicast_querier=1 multicast_router=2 hash_max=2048 hash_elasticity=5 ipv6_autoconf=false
litp create -t bridge -p /ms/network_interfaces/br1 -o device_name=br1 ipv6address="${ms_ipv6_834}" network_name=834  multicast_snooping=0

litp create -t vlan -p /ms/network_interfaces/br1_834 -o device_name='bond0.834' bridge=br1

litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}" master=bond1 rx_ring_buffer=2039 tx_ring_buffer=2039 txqueuelen=1250
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond1
litp create -t bond -p /ms/network_interfaces/b1 -o device_name='bond1' ipaddress="${ms_ip_ext}" network_name=data mode=1 arp_interval=2000 arp_validate=active arp_all_targets=any arp_ip_target="10.44.235.1"

# Bridges for ms for private network
litp create -t vlan -p /ms/network_interfaces/bond1_net1vm -o device_name=bond1.1 bridge=brnet1vm
litp create -t bridge -p /ms/network_interfaces/brnet1vm -o device_name=brnet1vm network_name=net1vm ipaddress="${net1vm_ip_ms}" ipv6address="${net1vm_ip6_ms}"  multicast_snooping=0

litp create -t vlan -p /ms/network_interfaces/bond1_net2vm -o device_name=bond1.2 bridge=brnet2vm
litp create -t bridge -p /ms/network_interfaces/brnet2vm -o device_name=brnet2vm network_name=net2vm ipaddress="${net2vm_ip_ms}"

litp create -t vlan -p /ms/network_interfaces/bond1_net3vm -o device_name=bond1.3 bridge=brnet3vm
litp create -t bridge -p /ms/network_interfaces/brnet3vm -o device_name=brnet3vm network_name=net3vm ipaddress="${net3vm_ip_ms}"

litp create -t vlan -p /ms/network_interfaces/bond1_net4vm -o device_name=bond1.4 bridge=brnet4vm
litp create -t bridge -p /ms/network_interfaces/brnet4vm -o device_name=brnet4vm network_name=net4vm ipaddress="${net4vm_ip_ms}"

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route834_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route837_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"

litp update -p /ms -o hostname="$ms_host_short"


# Create nodes
# MNs interface
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0 -o device_name='bond0' mode=1 miimon=100 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6[$i]}" network_name=mgmt

    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0_836  -o device_name='bond0.836'  ipaddress="${node_ip_836[$i]}" ipv6address="${node_ipv6_836[$i]}" network_name='nfs'

    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0_834  -o device_name='bond0.834' bridge=br_834

    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br_834  -o device_name=br_834 forwarding_delay=0 network_name=ipv61 ipv6address="${node_ipv6_834[$i]}" multicast_snooping=1 multicast_querier=1 multicast_router=2 hash_max=2048 hash_elasticity=5 ipv6_autoconf=false

    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0_837  -o device_name='bond0.837' ipv6address="${node_ipv6_837[$i]}" network_name=ipv62

    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0_vip1 -o device_name=bond0.85 bridge=br_vip1

    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br_vip1       -o device_name=br_vip1 forwarding_delay=0            network_name=net1vm    ipaddress="${VM_net1vm_ip[$i]}" ipv6address="${VM_net1vm_ip6[i]}" multicast_snooping=0

    litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" ipaddress="${node_ip_898[$i]}" ipv6address="${node_ipv6_898[$i]}" network_name=data rx_ring_buffer=0 tx_ring_buffer=0


    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1

    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route837_subnet}" gateway="${nodes_gateway}"

    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$[$i+1]

    # Creating Node Level Aliases
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config -t alias-node-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias -t alias -o alias_names="ms-alias" address="${ms_ip}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias_ipv6 -t alias -o alias_names="ms-aliasipv6" address="${ms_ipv6_835_short}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/ntp_server_alias_30 -t alias -o alias_names="ntp30" address="${ntp_alias}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/ntp_server_alias_4 -t alias -o alias_names="ntp4" address=10.44.86.212
    # Duplicate Node Level Aliases
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias_dup -t alias -o alias_names="ms-aliasdup,ms-alias" address="${ms_ip}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/alias_config/aliases/master_node_alias_ipv6_dup -t alias -o alias_names="ms-aliasipv6dup,ms-aliasipv6" address="${ms_ipv6_835_short}"
    # Finished Creating Node Level Aliases

done

# 169048 - PXE boot node1 on eth0 but use eth6 as mgmt network
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[0]}" pxe_boot_only=true
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[0]}" master=bond0

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[1]}" master=bond0
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[1]}" master=bond0 rx_ring_buffer=2039 tx_ring_buffer=2039


# different NTP services on each node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/ntp -s /software/items/ntp2
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp -s /software/items/ntp3

# HB and traffic networks - hardwired for 2 nodes
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1 rx_ring_buffer=453 tx_ring_buffer=4078 txqueuelen=1000
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[0]}" master=bond2 rx_ring_buffer=2039 tx_ring_buffer=2039 txqueuelen=750
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[0]}" master=bond2 rx_ring_buffer=2039 tx_ring_buffer=2039 txqueuelen=750
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[0]}" network_name=traffic2 ipaddress="${traf2_ip[0]}" rx_ring_buffer=2039 tx_ring_buffer=2039 txqueuelen=750


litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/bond2 -o device_name='bond2' mode=1 miimon=100 bridge=brtraffic1
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/brtraffic1 -o device_name=brtraffic1 network_name=traffic1 ipaddress="${traf1_ip[0]}"

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[1]}" master=bond2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[1]}" master=bond2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[1]}" network_name=traffic2 ipaddress="${traf2_ip[1]}"

litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/bond2 -o device_name='bond2' mode=1 miimon=100 bridge=brtraffic1
litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/brtraffic1 -o device_name=brtraffic1 network_name=traffic1 ipaddress="${traf1_ip[1]}"


litp create -t ntp-server -p /software/items/ntp1/servers/server1 -o server=ntp30
litp create -t ntp-server -p /software/items/ntp1/servers/server2 -o server=127.127.1.0
litp create -t ntp-server -p /software/items/ntp2/servers/server1 -o server=ntp30
litp create -t ntp-server -p /software/items/ntp2/servers/server2 -o server=10.44.86.107
litp create -t ntp-server -p /software/items/ntp3/servers/server1 -o server=ntp4
litp create -t ntp-server -p /software/items/ntp3/servers/server2 -o server=10.44.86.105


# SFS Filesystem for managed and unmanaged
litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs_management_ip}" user_name='support' password_key='key-for-sfs'
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"

# FS managed
# Ideally this FS should be deleted from the SFS server before each install
litp create -t sfs-pool -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1 -o name="SFS_Pool"
litp create -t sfs-cache -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/cache_objects/cache1 -o name=105cache1
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/managed1 -o path="/vx/ST105-managed1" size="1G" snap_size=100 cache_name=105cache1
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/managed2 -o path="/vx/ST105-managed2" size="40M" snap_size=200 cache_name=105cache1

litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/managed1/exports/ex1 -o  ipv4allowed_clients="${ms_ip_sfs},${node_ip_sfs[0]},${node_ip_sfs[1]}" options="rw,no_root_squash"
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/managed2/exports/ex1 -o  ipv4allowed_clients="${sfs_subnet}" options="rw,no_root_squash"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/managed1 -o export_path="/vx/ST105-managed1" provider="virtserv1" mount_point="/SFSmanaged1" mount_options="soft" network_name="${sfs_network}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/managed1a -o export_path="/vx/ST105-managed1" provider="virtserv1" mount_point="/SFSmanaged1a" mount_options="soft,clientaddr=10.44.235.142" network_name="${sfs_network}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/managed2 -o export_path="/vx/ST105-managed2" provider="virtserv1" mount_point="/SFSmanaged2" mount_options="soft" network_name="${sfs_network}"

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/managed1 -s /infrastructure/storage/nfs_mounts/managed1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/managed1 -s /infrastructure/storage/nfs_mounts/managed1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/managed1a -s /infrastructure/storage/nfs_mounts/managed1a
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/managed2 -s /infrastructure/storage/nfs_mounts/managed2
litp inherit -p /ms/file_systems/managed1 -s /infrastructure/storage/nfs_mounts/managed1


# FS unmanaged
# This FS must already exist on the SFS server
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/unmanaged1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/SFSunmanaged1" mount_options="hard,intr" network_name="${sfs_network}"

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1
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
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport=57004,57005 'name=112 hyperic tcp agent to server ports' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport=57006 'name=113 hyperic tcp server to agent port' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=013 sfsudp' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=012 sfstcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport=12987 'name=018 vmmonitord' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport=53 'name=021 DNS udp' proto=udp state=none
 litp create -p /ms/configs/fw_config/rules/fw_brs -t firewall-rule -o action=accept dport=1556,2821,4032,13724,13782 'name=022 backuprestore tcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_ntp -t firewall-rule -o action=accept dport=123 'name=029 NTP udp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dhcp_tcp -t firewall-rule -o action=accept dport=546,547,647,847 'name=030 DHCP tcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dhcp_udp -t firewall-rule -o action=accept dport=546,547,647,847 'name=031 DHCP udp' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_cobbler -t firewall-rule -o action=accept dport=25150,25151 'name=032 cobbler' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_cobbler_tcp -t firewall-rule -o action=accept dport=25150,25151 'name=033 cobbler' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_nexus -t firewall-rule -o action=accept dport=8080,8443 'name=034 nexus tcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_lserv -t firewall-rule -o action=accept dport=5093 'name=035 lserv' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_rpcbind -t firewall-rule -o action=accept dport=676 'name=036 rpcbind' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_loop_back -t firewall-rule -o action=accept iniface=lo 'name=02 loop back' proto=all
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_int -t firewall-rule -o action=accept provider=iptables dport=80 'name=106 allow http internal' proto=tcp state=NEW source=10.247.244.0/22
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_stor -t firewall-rule -o action=accept dport=80 'name=102 allow http storage' proto=tcp state=NEW provider=iptables source=10.140.2.0/24
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_serv -t firewall-rule -o action=accept dport=80 'name=103 allow http services' proto=tcp state=NEW provider=iptables source=10.151.9.128/26

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

litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnsudp -o name="071 dns" dport=53 proto="udp" state=none
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnstcp -o name="072 dns" dport=53 proto="tcp"

#open port for VM Monitor Health Check
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_vmhealth -o name="073 VM monitor health check" dport=12987 proto="tcp"

#open all ports on node2
litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/fw_config -o drop_all=false




# VCS Service Groups

# FAILOVER SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_cups -o deactivates=SG_new active=1 standby=1 name=FO_SG1 online_timeout=300 offline_timeout=50 node_list=n1,n2 dependency_list=""
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_luci -o active=1 standby=1 name=FO_SG2 online_timeout=300 offline_timeout=300 node_list=n2,n1 dependency_list="SG_cups"

# PARALLEL SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_httpd -o active=2 standby=0 name=PAR_SG1 online_timeout=300 offline_timeout=100 node_list="n2,n1"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_ricci -o active=2 standby=0 name=PAR_SG2 online_timeout=300 offline_timeout=60 node_list="n2,n1" dependency_list="SG_cups,SG_luci"


# LSB Services

litp create -t service -p /software/services/cups -o service_name=cups
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/applications/s1_cups -s /software/services/cups
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_cups/ha_configs/config -o status_interval=10 status_timeout=3600 restart_limit=0 startup_retry_limit=1 fault_on_monitor_timeouts=1 tolerance_limit=3 clean_timeout=70
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/SG_cups/triggers/trig1 -o trigger_type=nofailover

litp create -t service -p /software/services/luci -o service_name=luci
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/applications/s1_cups -s /software/services/luci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_luci/ha_configs/config -o status_interval=3600 status_timeout=20 restart_limit=50 startup_retry_limit=0 fault_on_monitor_timeouts=10 tolerance_limit=30 clean_timeout=700

litp create -t service -p /software/services/httpd -o service_name=httpd
litp inherit -p /deployments/d1/clusters/c1/services/SG_httpd/applications/s1_httpd -s /software/services/httpd
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_httpd/ha_configs/config -o status_interval=10 status_timeout=3600 restart_limit=1 startup_retry_limit=1 fault_on_monitor_timeouts=0 tolerance_limit=0 clean_timeout=700


litp create -t service -p /software/services/ricci -o service_name=ricci
litp inherit -p /deployments/d1/clusters/c1/services/SG_ricci/applications/s1_ricci -s /software/services/ricci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_ricci/ha_configs/config -o status_interval=3600 status_timeout=20 restart_limit=50 startup_retry_limit=1 fault_on_monitor_timeouts=1 tolerance_limit=1 clean_timeout=7000



#Create a SW Package
# RHEL 6.10 versions
litp create -t package -p /software/items/ricci -o name=ricci release=87.el6 version=0.16.2
litp inherit -p /software/services/ricci/packages/pkg1 -s /software/items/ricci

litp create -t package -p /software/items/httpd -o name=httpd release=69.el6 version=2.2.15
litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd

litp create -t package -p /software/items/luci -o name=luci release=93.el6 version=0.26.0
litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci


litp create -t package -p /software/items/cups -o name=cups release=79.el6 version=1.4.2 epoch=1
litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=69.el6
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=79.el6 epoch=1

#jdk
litp create -t package -p /software/items/jdk -o name=EXTRserverjre_CXP9035480
litp inherit -p /ms/items/java -s /software/items/jdk

for (( i=0; i<2; i++ )); do
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs -s /software/items/cups-libs
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java             -s /software/items/jdk
done

litp create -t package -p /software/items/libguestfs-tools-c -o name=libguestfs-tools-c
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c




# FAILOVER SG - with 10 SG and a VM
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/multiple_SG -o active=1 standby=1 name=FO_MULTISG online_timeout=300 offline_timeout=300 node_list=n1,n2

# Add sample packages
litp import /tmp/lsb_pkg 3pp

litp create -t package -p /software/items/pkg_lsb1 -o name=EXTR-lsbwrapper1
litp create -t  service -p /software/services/service1 -o service_name=test-lsb-01
litp inherit -p /software/services/service1/packages/pkg1 -s /software/items/pkg_lsb1
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/service1 -s /software/services/service1
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service1_conf -o status_interval=20 status_timeout=20 restart_limit=5 startup_retry_limit=1 service_id=service1 fault_on_monitor_timeouts=0 tolerance_limit=0 clean_timeout=7000
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/multiple_SG/triggers/trig1 -o trigger_type=nofailover

# Create md5 checksum
/usr/bin/md5sum /var/www/html/images/RHEL_7_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/RHEL_7_image.qcow2.md5

# Add one VM
litp create -t vm-image -p /software/images/image1 -o name=fmmed source_uri=http://${ms_host_short}/images/RHEL_7_image.qcow2
litp create -t vm-service -p /software/services/fmmed1 -o service_name=fmmed1 image_name=fmmed cpus=2 ram=2048M internal_status_check=on cleanup_command="/sbin/service fmmed1 force-stop"
litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/fmmed1 -s /software/services/fmmed1

# dual stack interface on private network
litp create -t vm-network-interface -p /software/services/fmmed1/vm_network_interfaces/net1 -o network_name=net1vm device_name=eth0 host_device=br_vip1 gateway=${net1vm_gw}
# ipv6 only interface
litp create -t vm-network-interface -p /software/services/fmmed1/vm_network_interfaces/net2 -o network_name=ipv61 device_name=eth1 host_device=br_834 gateway6=${ipv6_834_gateway}

#alias
litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/node1 -o alias_names="node1" address=${VM_net1vm_ip[0]}
litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/node2 -o alias_names="node2" address=${VM_net1vm_ip[1]}
litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/Ms1105 -o alias_names="${ms_host_short}" address="${net1vm_ip_ms}"

litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/node1_ipv6 -o alias_names="node1ipv6" address=${VM_net1vm_ip6[0]}
litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/node2_ipv6 -o alias_names="node2ipv6" address=${VM_net1vm_ip6[1]}
litp create -t vm-alias -p /software/services/fmmed1/vm_aliases/Ms1105_ipv6 -o alias_names="${ms_host_short}ipv6" address="${net1vm_ip6_ms}"

# vm-ram-mount
litp create -t vm-ram-mount -p /software/services/fmmed1/vm_ram_mounts/vm_ram-mount -o type=ramfs mount_point="/mnt/data1" mount_options="noexec,nodev,nosuid"

#repos and packages
litp create -t vm-yum-repo -p /software/services/fmmed1/vm_yum_repos/os -o name=os base_url="http://"${ms_host_short}"/6/os/x86_64"
litp create -t vm-yum-repo -p /software/services/fmmed1/vm_yum_repos/updates -o name=rhelPatches base_url="http://"${ms_host_short}"/6/updates/x86_64/Packages"
litp create -t vm-package -p /software/services/fmmed1/vm_packages/rhel7_tree -o name=tree
litp create -t vm-package -p /software/services/fmmed1/vm_packages/rhel7_unzip -o name=unzip

# key
litp create -t vm-ssh-key -p /software/services/fmmed1/vm_ssh_keys/support_key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxHQW3vVqhTikufpmOc+4XuJcCVscL4eDi3ahLKuj61tdjfPN0+HF8fJh+4ckpOpttCoZwM1AaBwyZx1H4t1K78E9CBEPwb9ftd57h/eFD9CnPtRIIg1eVEqGNNvhh6tAobEFSAQ1AuBrO5ye+pPGEXlXSb5ZU9ZYYJg4wAhNFlVX6zWCq6BqvzTQ7h4YFK4Bk8ACFOMD10N7rQEo6TVIyzkKoW0/HV61o537YFRav0kw9ZFyqS9jjWtui08GR1yIyhXb2jOiw20B5BnyaG3CR+tBmK6+EXzLVdf2D+3Lpf6nV2X76O5jd4OG5XW0NOOaXbAcqCzPQ39fwwBzgag6Sw== root@Ms1105"

# custom script
litp create -t vm-custom-script -p /software/services/fmmed1/vm_custom_script/customscript -o custom_script_names="cscript_crontab.sh" network_name=net1vm

litp update -p /deployments/d1/clusters/c1/services/multiple_SG/applications/fmmed1/ -o hostnames=105vm
litp update -p /deployments/d1/clusters/c1/services/multiple_SG/applications/fmmed1/vm_network_interfaces/net1 -o ipaddresses="${VM_net1vm_ip[2]}" ipv6addresses="${VM_net1vm_ip6[2]}"
litp update -p /deployments/d1/clusters/c1/services/multiple_SG/applications/fmmed1/vm_network_interfaces/net2 -o ipv6addresses="${VM_net834_ip6}"

litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/fmmed1_conf -o status_interval=30 status_timeout=30 restart_limit=5 startup_retry_limit=1 service_id=fmmed1


# Create the software packages
for (( i=2; i<10; i++ )); do
    litp create -t package -p /software/items/pkg_lsb$i -o name=EXTR-lsbwrapper$i
    litp create -t  service -p /software/services/service$i -o service_name=test-lsb-0$i
    litp inherit -p /software/services/service$i/packages/pkg$i -s /software/items/pkg_lsb$i
    litp inherit -p /deployments/d1/clusters/c1/services/multiple_SG/applications/service$i -s /software/services/service$i
    litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/multiple_SG/ha_configs/service$(($i))_conf -o status_interval=10 status_timeout=30 restart_limit=2 startup_retry_limit=2 service_id=service$i dependency_list=service$(($i-1)) fault_on_monitor_timeouts=$i tolerance_limit=$i clean_timeout=700
done;


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


# Mount VxVM Volume on cups (F/O)
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/spv1/volume_groups/vg_vmvx/file_systems/VXVM_FS_1
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/filesystems/fs2 -s /deployments/d1/clusters/c1/storage_profile/spv2/volume_groups/vg_vmvx/file_systems/VXVM_FS_2
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/filesystems/fs3 -s /deployments/d1/clusters/c1/storage_profile/spv3/volume_groups/vg_vmvx/file_systems/VXVM_FS_3

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

#Adding network hosts for vms
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm100 -o network_name=net1vm ip="${VM_net1vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf_vm101 -o network_name=net1vm ip="${VM_net1vm_ip[1]}"

#repos
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://"${ms_host_short}"/6/os/x86_64/HighAvailability"
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo

# Fencing disks
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid="${fen1_disk_uuid}" size=100M name=fencing_disk_1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid="${fen2_disk_uuid}" size=100M name=fencing_disk_2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid="${fen3_disk_uuid}" size=100M name=fencing_disk_3


# Sysparams
litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/sysctl
litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/sysctl

for (( i=0; i<${#node_sysname[@]}; i++ )); do
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_custom -o key="fs.file-max" value="26289446"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_max" value="5242880"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.wmem_default" value="655360"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_max" value="655360"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="kernel.core_pattern" value="/tmp/core.%e.pid%p.usr%u.sig%s.tim%t" value="205"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm5 -o key=net.ipv4.ip_forward value=1

  # routing config - as defined in node hardening doc
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening1 -o key=net.ipv6.conf.default.autoconf value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening2 -o key=net.ipv6.conf.default.accept_ra value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening3 -o key=net.ipv6.conf.default.accept_ra_defrtr value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening4 -o key=net.ipv6.conf.default.accept_ra_rtr_pref value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening5 -o key=net.ipv6.conf.default.accept_ra_pinfo value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening6 -o key=net.ipv6.conf.default.accept_source_route value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening7 -o key=net.ipv6.conf.default.accept_redirects value=0

  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening8 -o key=net.ipv6.conf.all.autoconf value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening9 -o key=net.ipv6.conf.all.accept_ra value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening10 -o key=net.ipv6.conf.all.accept_ra_defrtr value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening11 -o key=net.ipv6.conf.all.accept_ra_rtr_pref value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening12 -o key=net.ipv6.conf.all.accept_ra_pinfo value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening13 -o key=net.ipv6.conf.all.accept_source_route value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_hardening14 -o key=net.ipv6.conf.all.accept_redirects value=0
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_thresh -o key=net.ipv6.neigh.default.gc_thresh3 value=2048

done

litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_custom -o key="fs.file-max" value="26289448"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="kernel.core_pattern" value="/tmp/core.%e.pid%p.usr%u.sig%s.tim%t"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_thresh3 -o key=net.ipv6.neigh.default.gc_thresh3 value=2048

litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening1 -o key=net.ipv6.conf.default.autoconf value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening2 -o key=net.ipv6.conf.default.accept_ra value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening3 -o key=net.ipv6.conf.default.accept_ra_defrtr value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening4 -o key=net.ipv6.conf.default.accept_ra_rtr_pref value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening5 -o key=net.ipv6.conf.default.accept_ra_pinfo value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening6 -o key=net.ipv6.conf.default.accept_source_route value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening7 -o key=net.ipv6.conf.default.accept_redirects value=0

litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening8 -o key=net.ipv6.conf.all.autoconf value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening9 -o key=net.ipv6.conf.all.accept_ra value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening10 -o key=net.ipv6.conf.all.accept_ra_defrtr value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening11 -o key=net.ipv6.conf.all.accept_ra_rtr_pref value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening12 -o key=net.ipv6.conf.all.accept_ra_pinfo value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening13 -o key=net.ipv6.conf.all.accept_source_route value=0
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_hardening14 -o key=net.ipv6.conf.all.accept_redirects value=0



#ENM_DEP:Add 200+ MS Aliases
litp create -t alias-node-config -p /ms/configs/alias_config
litp create -t alias -p /ms/configs/alias_config/aliases/ms_alias_ntp -o alias_names="ntp30" address="${ntp_alias}"
for (( i=1; i<111; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ms_alias_$i -o alias_names=msalias$i address="10.44.86."$(($i+10))
    litp create -t alias -p /ms/configs/alias_config/aliases/ms_alias_dup_$i -o alias_names=msaliasdup$i,msalias$i address="10.44.86."$(($i+10))
done

#log rotate
litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate/rules/engine -o name="engine" path="/var/VRTSvcs/log/engine_A.log" size=100M rotate=50 copytruncate=true
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate/rules/syslog -o name="syslog" path="/var/log/cron,/var/log/maillog,/var/log/messages,/var/log/secure,/var/log/spooler" minsize=500M rotate=28 compress=true delaycompress=true rotate_every=day sharedscripts=true postrotate='/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true'

litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule        -p /ms/configs/logrotate/rules/syslog -o name="syslog" path="/var/log/cron,/var/log/maillog,/var/log/messages,/var/log/secure,/var/log/spooler" minsize=500M rotate=28 compress=true delaycompress=true rotate_every=day sharedscripts=true postrotate='/bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true'

#sentinel
litp create -t package -p /software/items/sentinel -o name=EXTRlitpsentinellicensemanager_CXP9031488
litp inherit -p /ms/items/sentinel -s /software/items/sentinel

litp create -t service -p /ms/services/sentinel -o service_name=sentinel

litp create -t service -p /software/services/sentinel -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

# Service Name / Package Mismatch
litp create -t package -p /software/items/svc_name_mismatch -o name="test_service_name"

litp create -t service -p /ms/services/svc_mismatch -o service_name="diff_service"
litp inherit -p /ms/services/svc_mismatch/packages/mismatch -s /software/items/svc_name_mismatch

litp create -t service -p /software/services/mismatch -o service_name="diff_service"
litp inherit -p /software/services/mismatch/packages/mismatch -s /software/items/svc_name_mismatch
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/mismatch -s /software/services/mismatch
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/mismatch -s /software/services/mismatch


#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,openvpn.com,example105one.com,example105two.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_1 -o ipaddress=10.44.86.212 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_2 -o ipaddress=fdde:4d7e:d471::834:4:4 position=2

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,openvpn.com,example105one.com,example105two.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_1 -o ipaddress=10.44.86.212 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_2 -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_3 -o ipaddress=fdde:4d7e:d471::834:4:4 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,openvpn.com,example105one.com,example105two.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_1 -o ipaddress=10.44.86.212 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_2 -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_3 -o ipaddress=fdde:4d7e:d471::834:4:4 position=3


# IPV6 routes
litp create -t route6 -p /infrastructure/networking/routes/route6_default -o subnet=::/0 gateway=${ipv6_835_gateway}
litp create -t route6 -p /infrastructure/networking/routes/route6_1 -o subnet=${ipv6_834_subnet} gateway=${ipv6_834_gateway}

litp inherit -p /ms/routes/route6_default -s /infrastructure/networking/routes/route6_default
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route6_default -s /infrastructure/networking/routes/route6_default
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route6_default -s /infrastructure/networking/routes/route6_default

litp import /tmp/3PP-irish-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-czech-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1
litp import /tmp/3PP-dutch-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-english-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1
litp import /tmp/3PP-finnish-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-french-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-german-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1
litp import /tmp/3PP-italian-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-klingon-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1
litp import /tmp/3PP-polish-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-portuguese-hungarian-slovak-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1
litp import /tmp/3PP-romanian-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-russian-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1
litp import /tmp/3PP-serbian-hello-1.0.0-1.noarch.rpm  /var/www/html/REPO1
litp import /tmp/3PP-spanish-hello-1.0.0-1.noarch.rpm /var/www/html/REPO1


litp create -t yum-repository -p /software/items/REPO1 -o name="REPO1" ms_url_path=/REPO1
litp inherit -s /software/items/REPO1 -p /deployments/d1/clusters/c1/nodes/n1/items/REPO1
litp inherit -s /software/items/REPO1 -p /deployments/d1/clusters/c1/nodes/n2/items/REPO1
litp inherit -s /software/items/REPO1 -p /ms/items/REPO1

# Individual package
litp create -t package -p /software/items/3pp-irish-hello -o name=3PP-irish-hello
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/3pp-irish-hello -s /software/items/3pp-irish-hello

# Package lists
litp create -p /software/items/hello_world1 -t package-list -o name=europe1 version=15
litp create -p /software/items/hello_world1/packages/czech -t package -o name=3PP-czech-hello
litp create -p /software/items/hello_world1/packages/dutch -t package -o name=3PP-dutch-hello
litp create -p /software/items/hello_world1/packages/english -t package -o name=3PP-english-hello
litp create -p /software/items/hello_world1/packages/finnish -t package -o name=3PP-finnish-hello
litp create -p /software/items/hello_world1/packages/french -t package -o name=3PP-french-hello
litp create -p /software/items/hello_world1/packages/german -t package -o name=3PP-german-hello
litp create -p /software/items/hello_world1/packages/italian -t package -o name=3PP-italian-hello

litp create -p /software/items/hello_world2 -t package-list -o name=europe2
litp create -p /software/items/hello_world2/packages/klingon -t package -o name=3PP-klingon-hello
litp create -p /software/items/hello_world2/packages/polish -t package -o name=3PP-polish-hello
litp create -p /software/items/hello_world2/packages/portuguese_hungarian_slovak -t package -o name=3PP-portuguese-hungarian-slovak-hello
litp create -p /software/items/hello_world2/packages/romanian -t package -o name=3PP-romanian-hello
litp create -p /software/items/hello_world2/packages/russian -t package -o name=3PP-russian-hello
litp create -p /software/items/hello_world2/packages/serbian -t package -o name=3PP-serbian-hello
litp create -p /software/items/hello_world2/packages/spanish -t package -o name=3PP-spanish-hello
litp inherit -p /ms/items/europe1 -s /software/items/hello_world1
litp inherit -p /ms/items/europe2 -s /software/items/hello_world2


# Add VM to MS
litp create -t vm-service -p /ms/services/msfmmed1 -o service_name=msfmmed1 image_name=fmmed cpus=2 ram=512M internal_status_check=off
litp create -t vm-network-interface -p /ms/services/msfmmed1/vm_network_interfaces/net1 -o network_name=mgmt device_name=eth0 host_device=br0 ipaddresses="${ms_vm_835}" ipv6addresses="${ms_vm_ipv6_835}"
# ipv4 only
litp create -t vm-network-interface -p /ms/services/msfmmed1/vm_network_interfaces/net2 -o network_name=net1vm device_name=eth1 host_device=brnet1vm ipaddresses="${ms_vm_net1}"
# ipv6 only
litp create -t vm-network-interface -p /ms/services/msfmmed1/vm_network_interfaces/net3 -o network_name=834 device_name=eth2 host_device=br1 ipv6addresses="${ms_vm_ipv6_834}" gateway6=${ipv6_834_gateway}
# vm-alias
litp create -t vm-alias -p /ms/services/msfmmed1/vm_aliases/ms1 -o alias_names="${ms_host_short}" address=10.44.86.105
litp create -t vm-alias -p /ms/services/msfmmed1/vm_aliases/ms1_ipv6 -o alias_names="${ms_host_short}" address="${ms_ipv6_835_short}"
# vm repo
litp create -t vm-yum-repo -p /ms/services/msfmmed1/vm_yum_repos/repo1 -o name=repo1 base_url="http://"${ms_host_short}"/REPO1"
# vm package
litp create -t vm-package -p /ms/services/msfmmed1/vm_packages/3pp-irish-hello -o name=3PP-irish-hello
# vm-disk
litp create -t vm-disk -p /ms/services/msfmmed1/vm_disks/vm_disk1 -o host_volume_group=vg1 host_file_system=fs2 mount_point=/vm_data_dir1
# vm-disk - unmounted on MS
litp create -t vm-disk -p /ms/services/msfmmed1/vm_disks/vm_disk2 -o host_volume_group=vg1 host_file_system=fs3 mount_point=/vm_data_dir2
# vm-ram-mount
litp create -t vm-ram-mount -p /ms/services/msfmmed1/vm_ram_mounts/vm-ram-mount -o type=tmpfs mount_point="/mnt/data1" mount_options="size=512M,noexec,nodev,nosuid"
# custom script
litp create -t vm-custom-script -p /ms/services/msfmmed1/vm_custom_script/customscript -o custom_script_names="cscript_crontab.sh"

# Items for LITPCDS-10650 plugin - config task replacement plugin
litp create -t story10650 -p /software/items/tc01_foobar1 -o name=tc01_foobar1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/testplug -s /software/items/tc01_foobar1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/testplug -s /software/items/tc01_foobar1

litp update -p /litp/logging -o force_debug=true

litp create_plan
