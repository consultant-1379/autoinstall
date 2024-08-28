 
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
litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support

litp create  -p /software/profiles/os_prof1  -t os-profile  -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create  -p /deployments/d1              -t deployment
litp create  -p /deployments/d1/clusters/c1  -t vcs-cluster -o cluster_type=sfha low_prio_net=data llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"
litp create  -p /infrastructure/systems/sys1 -t blade       -o system_name="${ms_sysname}"

# Add NTP alias with alias
litp create -t ntp-service -p /software/items/ntp1
litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done

litp update  -p /ms                    -o hostname="${ms_host}"
litp create  -p /ms/services/cobbler   -t cobbler-service
litp inherit -p /ms/system             -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp          -s /software/items/ntp1

# Create storage volume group 1 LVM
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_1 
litp create -t volume-group    -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1                      -o volume_group_name=vg_root
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd1 -o device_name=hd0_1
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd2 -o device_name=hd0_2
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd3 -o device_name=hd0_3
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd4 -o device_name=hd0_4

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root                         -t file-system     -o type=ext4 mount_point=/                size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap                         -t file-system     -o type=swap mount_point=swap             size=2G
for (( i=0; i<6; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS$i -t file-system -o type=ext4 mount_point=/LVM_mp_VG1_FS$i             size=200M snap_size=$((100-($i * 10)))
done

# Create storage volume group VXVM 2
litp create -p /infrastructure/storage/storage_profiles/profile_2                                                             -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0                                     -t volume-group    -o volume_group_name=vg_vxvm_0
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd1_vxvm           -t physical-device -o device_name=hd1
for (( i=0; i<7; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/file_systems/VxVM_VG2_$i -t file-system     -o type=vxfs mount_point=/VxVM_mp_VG2_FS$i size=500M snap_size=0
done
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

# Create storage volume group VXVM 3
litp create -p /infrastructure/storage/storage_profiles/profile_3 -t storage-profile -o volume_driver='vxvm'
for (( i=1; i<6; i++ )); do
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i                                -t volume-group    -o volume_group_name=vg_vxvm_$i
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i/physical_devices/hd_vxvm_$i    -t physical-device -o device_name=hd$(($i+1))
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i/file_systems/VxVM_VG3_$i    -t file-system     -o type=vxfs mount_point=/VxVM_mp_VG3_FS$i size=1050M snap_size=100
done
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp3 -s /infrastructure/storage/storage_profiles/profile_3

# Setup node disks, and node ilo's
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t blade -p /infrastructure/systems/sys$(($i+2))               -o system_name="${node_sysname[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_1 -o name=hd0_1 size=28G bootable=true  uuid="${node_disk1_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_2 -o name=hd0_2 size=4G  bootable=false uuid="${node_disk2_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_3 -o name=hd0_3 size=4G  bootable=false uuid="${node_disk3_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_4 -o name=hd0_4 size=4G  bootable=false uuid="${node_disk4_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk1   -o name=hd1   size=28G bootable=false uuid="${vxvm_disk_uuid[0]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk2   -o name=hd2   size=9G  bootable=false uuid="${vxvm_disk_uuid[1]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk3   -o name=hd3   size=5G  bootable=false uuid="${vxvm_disk_uuid[2]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk4   -o name=hd4   size=5G  bootable=false uuid="${vxvm_disk_uuid[3]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk5   -o name=hd5   size=5G  bootable=false uuid="${vxvm_disk_uuid[4]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk6   -o name=hd6   size=5G  bootable=false uuid="${vxvm_disk_uuid[5]}"
    litp create -t bmc   -p /infrastructure/systems/sys$(($i+2))/bmc           -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

# Routes 
litp create -t route   -p /infrastructure/networking/routes/route1            -o subnet="0.0.0.0/0"          gateway="${nodes_gateway}"
litp create -t route   -p /infrastructure/networking/routes/route_t1          -o subnet="${traf1gw_subnet}"  gateway="${traf1_ip[1]}"
litp create -t route   -p /infrastructure/networking/routes/route_t2          -o subnet="${traf2gw_subnet}"  gateway="${traf2_ip[1]}"
litp create -t route6  -p /infrastructure/networking/routes/route1_ipv6       -o subnet=fdde:4d7e:d471::835:0:0/96      gateway=fdde:4d7e:d471::835:90:200
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6       -o subnet=::/0                            gateway=fdde:4d7e:d471::835:1:1

# MS Routes
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}"    gateway="${nodes_gateway}"
#litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}"    gateway="${nodes_gateway}"
#litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}"    gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
#litp inherit -p /ms/routes/route6 -s /infrastructure/networking/routes/route1_ipv6
litp inherit -p /ms/routes/route7 -s /infrastructure/networking/routes/route2_ipv6

# Networks
litp create -t network -p /infrastructure/networking/networks/mgmt            -o name=mgmt      subnet="${nodes_subnet}"    litp_management=true
litp create -t network -p /infrastructure/networking/networks/data            -o name=data      subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/heartbeat1      -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2      -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1        -o name=traffic1  subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2        -o name=traffic2  subnet="${traf2_subnet}"
litp create -t network -p /infrastructure/networking/networks/subnet_834      -o name=netwk834
litp create -t network -p /infrastructure/networking/networks/subnet_836      -o name=netwk836  subnet="${route3_subnet}"
litp create -t network -p /infrastructure/networking/networks/subnet_837      -o name=netwk837  subnet="${route4_subnet}"

# Interfaces
litp create -t eth  -p /ms/network_interfaces/if0     -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0 
litp create -t eth  -p /ms/network_interfaces/if1     -o device_name=eth1 macaddress="${ms_eth1_mac}" network_name=data     ipaddress="${ms_ip_ext}"  ipv6address="${ms_ipv6_01}"
litp create -t eth  -p /ms/network_interfaces/if2     -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t eth  -p /ms/network_interfaces/if3     -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond0
litp create -t bond -p /ms/network_interfaces/b0      -o device_name='bond0' mode=1
litp create -t vlan -p /ms/network_interfaces/vlan835 -o device_name=bond0.835                        network_name=mgmt     ipaddress="${ms_ip}"      ipv6address="${ms_ipv6_00}"
litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=eth2.834                         network_name=netwk834                           ipv6address="${ms_ipv6_11}"
litp create -t vlan -p /ms/network_interfaces/vlan836 -o device_name=eth2.836                         network_name=netwk836 ipaddress="${ms_ip_ext1}" ipv6address="${ms_ipv6_12}"
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=eth2.837                         network_name=netwk837 ipaddress="${ms_ip_ext2}" ipv6address="${ms_ipv6_13}"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # Node misc
        litp create  -p /deployments/d1/clusters/c1/nodes/n$(($i+1))                    -t node                                       -o hostname="${node_hostname[$i]}"
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system             -s /infrastructure/systems/sys$(($i+2))
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os                 -s /software/profiles/os_prof1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile    -s /infrastructure/storage/storage_profiles/profile_1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1         -s /software/items/ntp1
    # Node Routes
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1      -s /infrastructure/networking/routes/route1
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2      -s /infrastructure/networking/routes/route1   -o subnet="${route2_subnet}"    gateway="${nodes_gateway}"
   #     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route3      -s /infrastructure/networking/routes/route1   -o subnet="${route3_subnet}"    gateway="${nodes_gateway}"
   #     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route4      -s /infrastructure/networking/routes/route1   -o subnet="${route4_subnet}"    gateway="${nodes_gateway}"
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route5      -s /infrastructure/networking/routes/route1   -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
   #     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1_ipv6 -s /infrastructure/networking/routes/route1_ipv6
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2_ipv6 -s /infrastructure/networking/routes/route2_ipv6
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/route_t1 -o subnet="${traf1gw_subnet}"   gateway="${traf1_ip[$i]}"
        litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/route_t2 -o subnet="${traf2gw_subnet}"   gateway="${traf2_ip[$i]}" 
done
# Heterogeneous networking set up - LITPCDS-4886 define a single IP resource on different NICs on different nodes across the cluster
# Network Node 1
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0           -o device_name=eth0 macaddress="${node_eth0_mac[0]}" master=bond0
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1           -o device_name=eth1 macaddress="${node_eth1_mac[0]}" network_name=data      ipaddress="${node_ip_ext[0]}"  ipv6address="${ipv6_01[0]}"
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=heartbeat1    
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=heartbeat2    
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4           -o device_name=eth4 macaddress="${node_eth4_mac[0]}" 
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5           -o device_name=eth5 macaddress="${node_eth5_mac[0]}" 
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7           -o device_name=eth7 macaddress="${node_eth7_mac[0]}" master=bond0
    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0            -o device_name=bond0      mode=1      network_name=mgmt      ipaddress="${node_ip[0]}"      ipv6address="${ipv6_00[0]}" 
#    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_mgmt       -o device_name=bond0.835                             network_name=mgmt      ipaddress="${node_ip[0]}"      ipv6address="${ipv6_00[0]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0_834        -o device_name=bond0.834                             network_name=netwk834                                 ipv6address="${ipv6_11[0]}"
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan_traffic1 -o device_name=eth4.4                                network_name=traffic1  ipaddress="${traf1_ip[0]}"     ipv6address="${ipv6_04[0]}"
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan836       -o device_name=eth4.836                              network_name=netwk836  ipaddress="${node_ip_ext1[0]}" ipv6address="${ipv6_12[0]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan_traffic2 -o device_name=eth5.5 	                              network_name=traffic2  ipaddress="${traf2_ip[0]}"     ipv6address="${ipv6_05[0]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan837       -o device_name=eth5.837                              network_name=netwk837  ipaddress="${node_ip_ext2[0]}" ipv6address="${ipv6_13[0]}" 
# Network Node 2
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0           -o device_name=eth0 macaddress="${node_eth0_mac[1]}" master=bond0
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1           -o device_name=eth1 macaddress="${node_eth1_mac[1]}" network_name=traffic1  ipaddress="${traf1_ip[1]}"     ipv6address="${ipv6_01[1]}"
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=heartbeat2
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4           -o device_name=eth4 macaddress="${node_eth4_mac[1]}" 
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5           -o device_name=eth5 macaddress="${node_eth5_mac[1]}" network_name=data      ipaddress="${node_ip_ext[1]}"  ipv6address="${ipv6_05[1]}"
    litp create -t  eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7           -o device_name=eth7 macaddress="${node_eth7_mac[1]}" master=bond0
    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0            -o device_name=bond0      mode=1      network_name=mgmt      ipaddress="${node_ip[1]}"      ipv6address="${ipv6_00[1]}" 
#    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_mgmt       -o device_name=bond0.835                             network_name=mgmt      ipaddress="${node_ip[1]}"      ipv6address="${ipv6_00[1]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan_traffic2 -o device_name=eth4.1                                network_name=traffic2  ipaddress="${traf2_ip[1]}"     ipv6address="${ipv6_04[1]}"
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan834       -o device_name=eth4.834                              network_name=netwk834                                 ipv6address="${ipv6_11[1]}"
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan836       -o device_name=eth4.836                              network_name=netwk836  ipaddress="${node_ip_ext1[1]}" ipv6address="${ipv6_12[1]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan837       -o device_name=eth4.837                              network_name=netwk837  ipaddress="${node_ip_ext2[1]}" ipv6address="${ipv6_13[1]}" 

# Alias
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias                -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="10.44.86.231"

litp create -t alias-node-config    -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config
litp create -t alias                -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/fwServer -o alias_names="fwServer","dot30","ciNode" address="10.44.86.30"

# NFS & SFS File systems
litp create -t sfs-service          -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs_management_ip}" user_name='support' password_key='key-for-sfs' pool_name="SFS_Pool"
litp create -t nfs-service          -p /infrastructure/storage/storage_providers/sp1             -o name="nfs1" ipv4address="${nfs_management_ip}"
litp create -t sfs-virtual-server   -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/exports/ex1         -o export_path="${sfs_prefix}_mgmt_sfs-fs1" ipv4allowed_clients="${ms_ip_ext2},${node_ip_ext2[0]},${node_ip_ext2[1]}" export_options="ro,no_root_squash,secure_locks" size="1G"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/exports/ex2         -o export_path="${sfs_prefix}_mgmt_sfs-fs2" ipv4allowed_clients="${ms_ip_ext2},${node_ip_ext2[0]},${node_ip_ext2[1]}" export_options="rw,no_root_squash,no_subtree_check" size="1G"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mount1     -o export_path="${sfs_prefix}-fs1"            provider="virtserv1" mount_point="/cluster1"      mount_options="soft,intr" network_name="netwk837"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mgmt_sfs01 -o export_path="${sfs_prefix}_mgmt_sfs-fs1"   provider="virtserv1" mount_point="/mgmt_sfs_fs01" mount_options="soft"      network_name="netwk837"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mgmt_sfs02 -o export_path="${sfs_prefix}_mgmt_sfs-fs2"   provider="virtserv1" mount_point="/mgmt_sfs_fs02" mount_options="soft"      network_name="netwk837"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nm1        -o export_path="${nfs_prefix}/dir_share_66_A" provider="nfs1"      mount_point="/nfs_dirA"      mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nm2        -o export_path="${nfs_prefix}/dir_share_66_B" provider="nfs1"      mount_point="/nfs_dirB"      mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nm3        -o export_path="${nfs_prefix}/dir_share_66_C" provider="nfs1"      mount_point="/nfs_dirC"      mount_options="soft,intr" network_name="mgmt"

litp inherit -p /ms/file_systems/fs1        -s /infrastructure/storage/nfs_mounts/mount1  # SFS
litp inherit -p /ms/file_systems/nfs_dir1   -s /infrastructure/storage/nfs_mounts/nm1     # NFS
litp inherit -p /ms/file_systems/nfs_dir2   -s /infrastructure/storage/nfs_mounts/nm2     
litp inherit -p /ms/file_systems/nfs_dir3   -s /infrastructure/storage/nfs_mounts/nm3
litp inherit -p /ms/file_systems/mgmt_sfs01 -s /infrastructure/storage/nfs_mounts/mgmt_sfs01 #-o network_name="mgmt"
litp inherit -p /ms/file_systems/mgmt_sfs02 -s /infrastructure/storage/nfs_mounts/mgmt_sfs02 #-o network_name="mgmt"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1        -s /infrastructure/storage/nfs_mounts/mount1  # SFS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nfs_dir1   -s /infrastructure/storage/nfs_mounts/nm1     # NFS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nfs_dir2   -s /infrastructure/storage/nfs_mounts/nm2
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nfs_dir3   -s /infrastructure/storage/nfs_mounts/nm3
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mgmt_sfs01 -s /infrastructure/storage/nfs_mounts/mgmt_sfs01
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mgmt_sfs02 -s /infrastructure/storage/nfs_mounts/mgmt_sfs02
done

# Firewall's
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule 	    -p /ms/configs/fw_config/rules/fw_icmp   -o name="100 icmp" proto="icmp"
litp create -t firewall-rule 	    -p /ms/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -t firewall-rule        -p /ms/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=53,111,2049,4001 proto=tcp
litp create -t firewall-rule        -p /ms/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=53,111,2049,4001 proto=udp

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t firewall-node-config 	-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmpv6 	-o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmp 	-o name="100 icmp"   proto="icmp"
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp 	-o 'name=011 nfsudp' dport=53,111,662,756,875,1110,2020,2049,4001,4045 proto=udp
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfstcp 	-o 'name=001 nfstcp' dport=53,111,662,756,875,1110,2020,2049,4001,4045 proto=tcp
done

#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_A -o ipaddress=fdde:4d7e:d471::834:4:4 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_C -o ipaddress=10.44.86.4 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.4 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.4 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

#Sysparms  
litp create -t sysparam-node-config -p /ms/configs/mynodesysctl 
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_MS01 -o key=net.ipv4.udp_mem                      value="24794401 33059201 49588801"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_MS02 -o key=net.ipv6.route.mtu_expires            value=599
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_MS03 -o key=net.ipv6.conf.eth2.max_desync_factor  value=599 
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm1 -o key="net.core.rmem_default"               value="100000000"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm2 -o key="net.core.rmem_max"                   value="100000000"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm3 -o key="net.core.wmem_default"               value="640000"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm4 -o key="net.core.wmem_max"                   value="640000"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm5 -o key="vm.swappiness"                       value="10"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm6 -o key="kernel.core_pattern"                 value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm7 -o key="vm.nr_hugepages"                     value="47104"
#litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group"                value="205"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
     litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm1 -o key="net.core.rmem_default"      value="100000000"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm2 -o key="net.core.rmem_max"          value="100000000"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm3 -o key="net.core.wmem_default"      value="640000"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm4 -o key="net.core.wmem_max"          value="640000"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm5 -o key="vm.swappiness"              value="10"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm6 -o key="kernel.core_pattern"        value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm7 -o key="vm.nr_hugepages"            value="47104"
#     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group"       value="205"
done;
     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl/params/sysctl_mn2_01       -o key=net.ipv6.conf.bond0.router_solicitation_interval value=5
     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl/params/sysctl_mn1_01       -o key=net.ipv6.neigh.eth4/4.base_reachable_time_ms         value="29999"

# Fencing disks
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o uuid="6006016011602d00707b8314c139e411" size=90M name=fencing_disk_1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o uuid="6006016011602d00727b8314c139e411" size=90M name=fencing_disk_2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o uuid="6006016011602d00747b8314c139e411" size=90M name=fencing_disk_3

# VCS Network Hosts
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/network_host_mgmt_ip4 -o network_name=mgmt     ip="${ms_gateway}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/network_host_mgmt_ip6 -o network_name=mgmt     ip="${ms_host_add6_00}"

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic1_10        -o network_name=traffic1 ip="${traf1_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic1_20        -o network_name=traffic1 ip="${traf1_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic2_10        -o network_name=traffic2 ip="${traf2_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic2_20        -o network_name=traffic2 ip="${traf1_ip[1]}"

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic1_ipv6_10   -o network_name=traffic1 ip="${host_add6_00[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic1_ipv6_20   -o network_name=traffic1 ip="${host_add6_01[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic2_ipv6_10   -o network_name=traffic2 ip="${host_add6_00[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/nh_traffic2_ipv6_20   -o network_name=traffic2 ip="${host_add6_01[1]}"

# Service Groups
# 2 F/O SGs - 1st SG #VIP=3x#AC 2nd SG  #VIP=4x#AC
# 2 PL  SGs - 3rd SG #VIP=5x#AC 4th SG  #VIP=2x#AC

# Runtime
x=0
SG_pkg[x]="cups";       SG_rel[x]="67.el6"; SG_ver[x]="1.4.2";      SG_VIP_count[x]=3;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=40   status_timeout[x]=30    restart_limit[x]=3      startup_retry_limit[x]=2     node_list[x]="n2,n1" dependency_list[x]="SG_ricci" x=$[$x+1]
SG_pkg[x]="ricci";      SG_rel[x]="75.el6";     SG_ver[x]="0.16.2";     SG_VIP_count[x]=$[2*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=1000 status_timeout[x]=1000  restart_limit[x]=1000   startup_retry_limit[x]=1000  node_list[x]="n1,n2" x=$[$x+1]

vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" version="${SG_ver[$x]}" release="${SG_rel[$x]}"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs_"${SG_pkg[$x]}" online_timeout=45 node_list="${node_list[$x]}" dependency_list="${dependency_list[$x]}" 
litp create -t lsb-runtime           -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/rt_"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}" status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}"
litp inherit                         -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/rt_"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
        for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/rt_"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/rt_"${SG_pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip_ipv6[$vip_count]}" network_name=traffic2
                vip_count=($vip_count+1)
        done
done

# Service
x=0
SG_pkg[x]="luci";       SG_rel[x]="63.el6";     SG_ver[x]="0.26.0";     SG_VIP_count[x]=4;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=10   status_timeout[x]=10    restart_limit[x]=0      startup_retry_limit[x]=0     node_list[x]="n1,n2" dependency_list[x]="SG_dovecot,SG_httpd,SG_ricci,SG_cups" x=$[$x+1]
SG_pkg[x]="httpd";      SG_rel[x]="39.el6";     SG_ver[x]="2.2.15";     SG_VIP_count[x]=$[5*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20   status_timeout[x]=30    restart_limit[x]=30     startup_retry_limit[x]=40    node_list[x]="n2,n1" dependency_list[x]="SG_cups" x=$[$x+1]
SG_pkg[x]="dovecot";    SG_rel[x]="7.el6_5.1";      SG_ver[x]="2.0.9";      SG_VIP_count[x]=$[0*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20   status_timeout[x]=30    restart_limit[x]=30     startup_retry_limit[x]=40    node_list[x]="n2,n1" dependency_list[x]="SG_ricci,SG_httpd" x=$[$x+1]


vip_count=10
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" version="${SG_ver[$x]}" release="${SG_rel[$x]}"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs_"${SG_pkg[$x]}" online_timeout=45 node_list="${node_list[$x]}" dependency_list="${dependency_list[$x]}"
litp create -t ha-service-config     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ha_configs/conf1 -o status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}" 
litp create -t service  -p /software/services/"${SG_pkg[$x]}"   -o service_name="${SG_pkg[$x]}"
litp inherit            -p /software/services/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
litp inherit            -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/applications/s1_"${SG_pkg[$x]}" -s /software/services/"${SG_pkg[$x]}"
        for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
                litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip_ipv6[$vip_count]}" network_name=traffic2
                vip_count=($vip_count+1)
        done
done

# Add VxVM FS to F/O SG
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/runtimes/rt_cups/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_1/file_systems/VxVM_VG3_1
litp inherit -p /deployments/d1/clusters/c1/services/SG_cups/runtimes/rt_cups/filesystems/fs2 -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_2/file_systems/VxVM_VG3_2
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs3                  -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_3/file_systems/VxVM_VG3_3
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs4                  -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_4/file_systems/VxVM_VG3_4
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs5                  -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_5/file_systems/VxVM_VG3_5
litp inherit -p /deployments/d1/clusters/c1/services/SG_luci/filesystems/fs6                  -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vg_vxvm_0/file_systems/VxVM_VG2_6


# Add Packages 
litp create -t package -p /software/items/openjdk     -o name=java-1.7.0-openjdk
litp create -t package -p /software/items/cups-libs   -o name=cups-libs   version=1.4.2  release=67.el6
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp inherit -p /ms/items/java -s /software/items/openjdk
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java        -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs   -s /software/items/cups-libs
done;

# Update packages  LITPCDS-7747 
litp update -p /software/items/dovecot -o epoch=1
litp update -p /software/items/cups -o epoch=1
litp update -p /software/items/cups-libs -o epoch=1

# Issue with cups versions, remove when issue resolved LITPCDS-6244
#litp update -p /software/items/cups 		-d version -d release
#litp update -p /software/items/cups-libs    	-d version -d release
#litp update -p /software/items/httpd 		-d version -d release
#litp update -p /software/items/httpd-tools   	-d version -d release
#litp update -p /software/items/luci 		-d version -d release
#litp update -p /software/items/ricci		-d version -d release

#litp update -p /deployments/d1/clusters/c1/nodes/n1/routes/traffic1_gw -o gateway=10.19.66.10
#litp update -p /deployments/d1/clusters/c1/nodes/n1/routes/traffic2_gw -o gateway=10.20.66.10
#litp update -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic1_gw -o gateway=10.19.66.20
#litp update -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic2_gw -o gateway=10.20.66.20


litp create_plan

