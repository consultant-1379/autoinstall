 
#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Deployment used for 10.44.86.86
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

# Plugin Install
for (( i=0; i<${#rpms[@]}; i++ )); do
    # import plugin into litp repo
    litp import "/tmp/${rpms[$i]}" litp
    # install plugin 
    expect /tmp/root_yum_install_pkg.exp "${ms_host}" "${rpms[$i]%%-*}"
done

# ENM ISO import commands
#expect /tmp/root_import_iso.exp "${ms_host}" "${enm_iso}"
#litp load -p /software -f /tmp/enm_package_2.xml --merge
#litp inherit -p /ms/items/model_repo -s /software/items/model_repo
#litp inherit -p /ms/items/model_package -s /software/items/model_package
#litp inherit -p /ms/items/ms_repo -s /software/items/ms_repo
#litp inherit -p /ms/items/common_repo -s /software/items/common_repo
#litp inherit -p /ms/items/db_repo -s /software/items/db_repo
#litp inherit -p /ms/items/services_repo -s /software/items/services_repo

litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${nas_support_password}"
litp import /tmp/lsb_pkg 3pp

litp create  -p /software/profiles/os_prof1  -t os-profile  -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create  -p /deployments/d1              -t deployment
litp create  -p /deployments/d1/clusters/c1  -t vcs-cluster -o cluster_type=sfha low_prio_net=data llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}" critical_service="cups" app_agent_num_threads=9 default_nic_monitor=netstat
litp create  -p /infrastructure/systems/sys1 -t blade       -o system_name="${ms_sysname}"


# Add NTP alias with alias
litp create -t ntp-service -p /software/items/ntp1
litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp1/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done


litp create -t ntp-service -p /software/items/ntp2
litp create -t ntp-server -p /software/items/ntp2/servers/server1 -o server=10.44.86.4
litp create -t ntp-server -p /software/items/ntp2/servers/server2 -o server=${ms_host}
litp create -t ntp-server -p /software/items/ntp2/servers/server3 -o server=ntpAliasName3

litp create -t alias-node-config -p /ms/configs/alias_config
for (( i=0; i<2; i++ )); do
        litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias$(($i+1)) -o alias_names=ntpAliasName$(($i+1)) address="${ntp_ip[$i+1]}"
        litp create -t ntp-server -p /software/items/ntp2/servers/server$(($i+1)) -o server=ntpAliasName$(($i+1))
done

# Add ms aliases
litp create -t alias-node-config -p /ms/configs/ms_alias_config
for ((i=0 ; i <100 ; i++)); do
        litp create -t alias -p /ms/configs/ms_alias_config/aliases/ms_alias_$(($i+1)) -o alias_names=msalias$(($i+1)) address=$ipv6_835_tp$(($i+1))
done

litp update  -p /ms                    -o hostname="${ms_host}"
litp create  -p /ms/services/cobbler   -t cobbler-service
litp inherit -p /ms/system             -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp          -s /software/items/ntp1

# Setup MS disk and storage_profile with FS
litp create  -t disk                -p /infrastructure/systems/sys1/disks/d1 -o name="hd1" size=550G bootable="true" uuid=$ms_disk_uuid
litp create  -t storage-profile     -p /infrastructure/storage/storage_profiles/sp1
litp create  -t volume-group        -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1 -o volume_group_name="vg_root"
litp create  -t file-system         -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/fs1 -o type="ext4" mount_point="/mount_ms_fs1" size="100M" snap_size="5" snap_external="false" backup_snap_size=5
litp create  -t physical-device     -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/physical_devices/pd1 -o device_name="hd1"
litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/sp1

# Create storage volume group 1 LVM
litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_1 
litp create -t volume-group    -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1                      -o volume_group_name=vg_root
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd1 -o device_name=hd0_1
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd2 -o device_name=hd0_2
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd3 -o device_name=hd0_3
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd4 -o device_name=hd0_4

litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root                         -t file-system     -o type=ext4 mount_point=/                size=8G   snap_size=50
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap                         -t file-system     -o type=swap mount_point=swap             size=2G   snap_size=50
# KS FS modelling
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/root -o type=ext4 mount_point=/ size=15G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/home -o type=ext4 mount_point=/home size=6G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var_log -o type=ext4 mount_point=/var/log size=20G snap_size=0 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var_www -o type=ext4 mount_point=/var/www size=70G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/var -o type=ext4 mount_point=/var size=15G snap_size=100 backup_snap_size=100
litp create -t file-system -p /infrastructure/storage/storage_profiles/sp1/volume_groups/vg1/file_systems/software -o type=ext4 mount_point=/software size=50G snap_size=0 backup_snap_size=0
for (( i=0; i<6; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_VG1_FS$i -t file-system -o type=ext4 mount_point=/LVM_mp_VG1_FS$i size=200M snap_size=$((100-($i * 10))) backup_snap_size=$((100-($i * 10)))
done


litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/LVM_no_snap -t file-system -o type=ext4 mount_point=/LVM_no_snap size=100M snap_size=5 snap_external=true


# Create storage volume group VXVM 2
litp create -p /infrastructure/storage/storage_profiles/profile_2                                                             -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0                                     -t volume-group    -o volume_group_name=vg_vxvm_0
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd1_vxvm           -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd2_vxvm           -t physical-device -o device_name=hd_vxvm8
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/physical_devices/hd3_vxvm           -t physical-device -o device_name=hd_vxvm9
#for (( i=0; i<7; i++ )); do
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg_vxvm_0/file_systems/VxVM_VG2_1 -t file-system     -o type=vxfs mount_point=/VxVM_mp_VG2_FS1 size=50M snap_size=30 backup_snap_size=30
#done

# Unmounted FS1 for LVM volume group vg1
litp create -t file-system -p  /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/unmounted_fs1 -o type=ext4 size=52M snap_size=30 backup_snap_size=30


# Unmounted FS2 for LVM volume group vg1
litp create -t file-system -p  /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/unmounted_fs2 -o type=ext4 size=52M snap_size=30 backup_snap_size=30


# Create storage volume group VXVM 3
litp create -p /infrastructure/storage/storage_profiles/profile_3 -t storage-profile -o volume_driver='vxvm'
for (( i=1; i<6; i++ )); do
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i                                -t volume-group    -o volume_group_name=vg_vxvm_$i
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i/physical_devices/hd_vxvm_$i    -t physical-device -o device_name=hd$(($i+1))
    litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg_vxvm_$i/file_systems/VxVM_VG3_$i       -t file-system     -o type=vxfs mount_point=/VxVM_mp_VG3_FS$i size=1050M snap_size=100 backup_snap_size=50
done

# Adding a new VG vxvm for testing the external snapshot feature
litp create -p /infrastructure/storage/storage_profiles/profile_5                                                              -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_5/volume_groups/vg_vxvm_0_snap                                 -t volume-group    -o volume_group_name=no_snap
litp create -p /infrastructure/storage/storage_profiles/profile_5/volume_groups/vg_vxvm_0_snap/physical_devices/hd1_vxvm_snap  -t physical-device -o device_name=hd7
litp create -p /infrastructure/storage/storage_profiles/profile_5/volume_groups/vg_vxvm_0_snap/file_systems/No_snap            -t file-system     -o type=vxfs mount_point=/no_snap size=30M snap_size=0 backup_snap_size=0 snap_external=true

# Inherit the clusters storage profiles from infrastructures VxVm storage profiles
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp3 -s /infrastructure/storage/storage_profiles/profile_3
litp inherit -p  /deployments/d1/clusters/c1/storage_profile/sp5 -s /infrastructure/storage/storage_profiles/profile_5

# Setup node disks, and node ILOs for cluster 1
for (( i=0; i<2; i++ )); do
    litp create -t blade -p /infrastructure/systems/sys$(($i+2))               -o system_name="${node_sysname[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_1 -o name=hd0_1      size=28G  bootable=true  uuid="${node_disk1_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_2 -o name=hd0_2      size=4G   bootable=false uuid="${node_disk2_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_3 -o name=hd0_3      size=4G   bootable=false uuid="${node_disk3_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_4 -o name=hd0_4      size=4G   bootable=false uuid="${node_disk4_uuid[$i]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk0_5 -o name=hd0_5      size=300M bootable=false uuid="${node_disk5_uuid[$i]}" 
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk1   -o name=hd1        size=28G  bootable=false uuid="${vxvm_disk_uuid[0]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk2   -o name=hd2        size=9G   bootable=false uuid="${vxvm_disk_uuid[1]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk3   -o name=hd3        size=5G   bootable=false uuid="${vxvm_disk_uuid[2]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk4   -o name=hd4        size=5G   bootable=false uuid="${vxvm_disk_uuid[3]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk5   -o name=hd5        size=5G   bootable=false uuid="${vxvm_disk_uuid[4]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk6   -o name=hd6        size=5G   bootable=false uuid="${vxvm_disk_uuid[5]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/disk7   -o name=hd7        size=50M  bootable=false uuid="${vxvm_disk_uuid[6]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/vxvm8   -o name=hd_vxvm8   size=80M  bootable=false uuid="${vxvm_disk_uuid[7]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/vxvm9   -o name=hd_vxvm9   size=80M  bootable=false uuid="${vxvm_disk_uuid[8]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/vxvm10  -o name=hd_vxvm10  size=80M  bootable=false uuid="${vxvm_disk_uuid[9]}"
    litp create -t disk  -p /infrastructure/systems/sys$(($i+2))/disks/vxvm11  -o name=hd_vxvm11  size=80M  bootable=false uuid="${vxvm_disk_uuid[10]}"
    litp create -t bmc   -p /infrastructure/systems/sys$(($i+2))/bmc           -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

# Routes 
litp create -t route   -p /infrastructure/networking/routes/route1            -o subnet="0.0.0.0/0"          gateway="${nodes_gateway}"
litp create -t route   -p /infrastructure/networking/routes/route_t1          -o subnet="${traf1gw_subnet}"  gateway="${traf1_ip[1]}"
litp create -t route   -p /infrastructure/networking/routes/route_t2          -o subnet="${traf2gw_subnet}"  gateway="${traf2_ip[1]}"
litp create -t route6  -p /infrastructure/networking/routes/route1_ipv6       -o subnet="${route_835_subnet_ipv6}"      gateway="${route_835_gw_ipv6}"
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6       -o subnet=::/0                            gateway="${route_835_gw_ipv6}"

# MS Routes
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}"    gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
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
litp create -t eth  -p /ms/network_interfaces/if0     -o device_name=eth0 macaddress="${ms_eth0_mac}"
litp create -t eth  -p /ms/network_interfaces/if1     -o device_name=eth1 macaddress="${ms_eth1_mac}" network_name=data     ipaddress="${ms_ip_ext}"  ipv6address="${ms_ipv6_01}"
litp create -t eth  -p /ms/network_interfaces/if2     -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=eth2.834                         network_name=netwk834                           ipv6address="${ms_ipv6_11}"
litp create -t vlan -p /ms/network_interfaces/vlan836 -o device_name=eth2.836                         network_name=netwk836 ipaddress="${ms_ip_ext1}" ipv6address="${ms_ipv6_12}"
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=eth2.837                         network_name=netwk837 ipaddress="${ms_ip_ext2}" ipv6address="${ms_ipv6_13}"

# bridge the mgmt vlan
litp create -t vlan -p /ms/network_interfaces/vlan835 -o device_name=eth0.835 bridge=br0
litp create -t bridge -p /ms/network_interfaces/br0 -o network_name=mgmt  ipaddress="${ms_ip}"  ipv6address="${ms_ipv6_00}" device_name=br0 multicast_snooping=0

# MS Sysctrl params
litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding01 -o key="net.ipv6.conf.default.autoconf" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding02 -o key="net.ipv6.conf.default.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding03 -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding04 -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding05 -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding06 -o key="net.ipv6.conf.default.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding07 -o key="net.ipv6.conf.default.accept_redirects" value="0"

litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding08 -o key="net.ipv6.conf.all.autoconf" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding09 -o key="net.ipv6.conf.all.accept_ra" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding10 -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding11 -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding12 -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding13 -o key="net.ipv6.conf.all.accept_source_route" value="0"
litp create -t sysparam -p /ms/configs/sysctl/params/mynodesysctl_ipv6_harding14 -o key="net.ipv6.conf.all.accept_redirects" value="0"

for (( i=0; i<2; i++ )); do
    # Node misc
    litp create  -p /deployments/d1/clusters/c1/nodes/n$(($i+1))                    -t node                                       -o hostname="${node_hostname[$i]}" 
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system             -s /infrastructure/systems/sys$(($i+2))
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os                 -s /software/profiles/os_prof1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile    -s /infrastructure/storage/storage_profiles/profile_1
    # Node Routes
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1      -s /infrastructure/networking/routes/route1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2      -s /infrastructure/networking/routes/route1   -o subnet="${route2_subnet}"    gateway="${nodes_gateway}"
    # litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route3      -s /infrastructure/networking/routes/route1   -o subnet="${route3_subnet}"    gateway="${nodes_gateway}"
    # litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route4      -s /infrastructure/networking/routes/route1   -o subnet="${route4_subnet}"    gateway="${nodes_gateway}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route5      -s /infrastructure/networking/routes/route1   -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
    # litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1_ipv6 -s /infrastructure/networking/routes/route1_ipv6
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route2_ipv6 -s /infrastructure/networking/routes/route2_ipv6
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/route_t1 -o subnet="${traf1gw_subnet}"   gateway="${traf1_ip[$i]}"
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/route_t2 -o subnet="${traf2gw_subnet}"   gateway="${traf2_ip[$i]}" 

    # Node Sysctrl Params rules
    litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl

    # Sysparam for nodes
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding01 -o key="net.ipv6.conf.default.autoconf" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding02 -o key="net.ipv6.conf.default.accept_ra" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding03 -o key="net.ipv6.conf.default.accept_ra_defrtr" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding04 -o key="net.ipv6.conf.default.accept_ra_rtr_pref" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding05 -o key="net.ipv6.conf.default.accept_ra_pinfo" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding06 -o key="net.ipv6.conf.default.accept_source_route" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding07 -o key="net.ipv6.conf.default.accept_redirects" value="0"

    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding08 -o key="net.ipv6.conf.all.autoconf" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding09 -o key="net.ipv6.conf.all.accept_ra" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding10 -o key="net.ipv6.conf.all.accept_ra_defrtr" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding11 -o key="net.ipv6.conf.all.accept_ra_rtr_pref" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding12 -o key="net.ipv6.conf.all.accept_ra_pinfo" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding13 -o key="net.ipv6.conf.all.accept_source_route" value="0"
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/mynodesysctl/params/mynodesysctl_ipv6_harding14 -o key="net.ipv6.conf.all.accept_redirects" value="0"
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
    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 -o device_name=bond0 mode=1 bridge=br0 arp_interval=2400  arp_ip_target=10.44.86.65,10.44.235.1,10.44.84.1,10.44.86.1,10.44.86.193,10.44.86.129


#bridge mgmt bond
    litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/br0            -o device_name=br0  network_name=mgmt      ipaddress="${node_ip[0]}"      ipv6address="${ipv6_00[0]}" multicast_snooping=0 multicast_snooping=1 hash_max=1024 multicast_querier=1 multicast_router=2

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
    litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 -o device_name=bond0 mode=1 bridge=br0 arp_interval=1600 arp_ip_target=10.44.86.65,10.44.235.1,10.44.84.1,10.44.86.1,10.44.86.193,10.44.86.129

  litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/br0          -o device_name=br0 network_name=mgmt      ipaddress="${node_ip[1]}"      ipv6address="${ipv6_00[1]}" multicast_snooping=1 hash_max=1024 multicast_querier=1 multicast_router=2


#    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0_mgmt       -o device_name=bond0.835                             network_name=mgmt      ipaddress="${node_ip[1]}"      ipv6address="${ipv6_00[1]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan_traffic2 -o device_name=eth4.1                                network_name=traffic2  ipaddress="${traf2_ip[1]}"     ipv6address="${ipv6_04[1]}"
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan834       -o device_name=eth4.834                              network_name=netwk834                                 ipv6address="${ipv6_11[1]}"
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan836       -o device_name=eth4.836                              network_name=netwk836  ipaddress="${node_ip_ext1[1]}" ipv6address="${ipv6_12[1]}" 
    litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan837       -o device_name=eth4.837                              network_name=netwk837  ipaddress="${node_ip_ext2[1]}" ipv6address="${ipv6_13[1]}" 

# Alias
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias                -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="${sfs_management_ip}"

litp create -t alias-node-config    -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config
litp create -t alias                -p /deployments/d1/clusters/c1/nodes/n2/configs/alias_config/aliases/fwServer -o alias_names="fwServer","dot30","ciNode,ntpAliasName3" address="${ntp_ip[1]}"

# NTP on n2 only
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp -s /software/items/ntp2

# NFS & SFS File systems for multiple pools
litp create -t sfs-service          -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs_management_ip}" user_name='support' password_key='key-for-sfs' # pool_name="SFS_Pool"
litp create -t nfs-service          -p /infrastructure/storage/storage_providers/sp1             -o name="nfs1" ipv4address="${nfs_management_ip}"
litp create -t sfs-virtual-server   -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1 -o name="SFS_Pool"
litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2 -o name="ST_Pool"
litp create -t sfs-cache            -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/cache_objects/cache1 -o name="ST66_cache"
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1 -o path="${sfs_prefix}_mgmt_sfs_fs1" size='100M' snap_size='130' cache_name="ST66_cache" 
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2 -o path="${sfs_prefix}_mgmt_sfs_fs2" size='100M' snap_size='230' cache_name="ST66_cache"
litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/mgmt_fs3 -o path="${sfs_prefix}_mgmt_sfs_fs3" size='100M' snap_size='130' cache_name="ST66_cache"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1/exports/ex1         -o ipv4allowed_clients="${ms_ip_nas},${node_ip_nas[0]},${node_ip_nas[1]}" options="ro,no_root_squash,secure_locks"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl2/file_systems/mgmt_fs3/exports/ex1         -o ipv4allowed_clients="${ms_ip_nas},${node_ip_nas[0]},${node_ip_nas[1]}" options="rw,no_root_squash,no_subtree_check"
litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2/exports/ex1         -o ipv4allowed_clients="${ms_ip_nas},${node_ip_nas[0]},${node_ip_nas[1]}" options="ro,no_root_squash,secure_locks"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mount1     -o export_path="${sfs_prefix}-fs1"            provider="virtserv1" mount_point="/cluster1"      mount_options="soft,intr" network_name="${nas_network}"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mgmt_sfs01 -o export_path="${sfs_prefix}_mgmt_sfs_fs1"   provider="virtserv1" mount_point="/mgmt_sfs_fs01" mount_options="soft"      network_name="${nas_network}"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mgmt_sfs02 -o export_path="${sfs_prefix}_mgmt_sfs_fs2"   provider="virtserv1" mount_point="/mgmt_sfs_fs02" mount_options="soft"      network_name="${nas_network}"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nm1        -o export_path="${nfs_prefix}/dir_share_66_A" provider="nfs1"      mount_point="/nfs_dirA"      mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nm2        -o export_path="${nfs_prefix}/dir_share_66_B" provider="nfs1"      mount_point="/nfs_dirB"      mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/nm3        -o export_path="${nfs_prefix}/dir_share_66_C" provider="nfs1"      mount_point="/nfs_dirC"      mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount            -p /infrastructure/storage/nfs_mounts/mgmt_sfs03 -o export_path="${sfs_prefix}_mgmt_sfs_fs3"   provider="virtserv1" mount_point="/mgmt_sfs_fs03" mount_options="soft"      network_name="${nas_network}"

litp inherit -p /ms/file_systems/fs1        -s /infrastructure/storage/nfs_mounts/mount1  # SFS
litp inherit -p /ms/file_systems/nfs_dir1   -s /infrastructure/storage/nfs_mounts/nm1     # NFS
litp inherit -p /ms/file_systems/nfs_dir2   -s /infrastructure/storage/nfs_mounts/nm2     
litp inherit -p /ms/file_systems/nfs_dir3   -s /infrastructure/storage/nfs_mounts/nm3
litp inherit -p /ms/file_systems/mgmt_sfs01 -s /infrastructure/storage/nfs_mounts/mgmt_sfs01 #-o network_name="mgmt"
litp inherit -p /ms/file_systems/mgmt_sfs02 -s /infrastructure/storage/nfs_mounts/mgmt_sfs02 #-o network_name="mgmt"

for (( i=0; i<2; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1        -s /infrastructure/storage/nfs_mounts/mount1  # SFS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nfs_dir1   -s /infrastructure/storage/nfs_mounts/nm1     # NFS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nfs_dir2   -s /infrastructure/storage/nfs_mounts/nm2
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nfs_dir3   -s /infrastructure/storage/nfs_mounts/nm3
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mgmt_sfs01 -s /infrastructure/storage/nfs_mounts/mgmt_sfs01
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mgmt_sfs02 -s /infrastructure/storage/nfs_mounts/mgmt_sfs02
done

# MS Firewall and Rules
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -p /ms/configs/fw_config/rules/fw_icmp -t firewall-rule -o action=accept 'name=100 icmp' proto=icmp
litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_in -t firewall-rule -o action=accept chain=INPUT dport=57004,57005 'name=112 hyperic tcp agent to server ports' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_hyperic_server_out -t firewall-rule -o action=accept chain=OUTPUT dport=57006 'name=113 hyperic tcp server to agent port' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_sfsudp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=013 sfsudp' proto=udp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_sfstcp -t firewall-rule -o action=accept dport=111,2049,4011,4001 'name=012 sfstcp' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_vmmonitord -t firewall-rule -o action=accept dport=12987 'name=018 vmmonitord' proto=tcp state=NEW
 litp create -p /ms/configs/fw_config/rules/fw_dns -t firewall-rule -o action=accept dport=53 'name=021 DNS udp' proto=udp state=NEW
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
 litp create -p /ms/configs/fw_config/rules/fw_http_allow_bkp -t firewall-rule -o action=accept dport=80 'name=104 allow http backup' proto=tcp state=NEW provider=iptables source=10.151.24.0/23
 litp create -p /ms/configs/fw_config/rules/fw_http_block -t firewall-rule -o action=accept dport=80 'name=105 drop http' proto=tcp state=NEW provider=iptables

for (( i=0; i<2; i++ )); do
    litp create -t firewall-node-config 	-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmpv6 	-o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmp 	-o name="100 icmp"   proto="icmp"
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp 	-o 'name=011 nfsudp' dport=53,111,662,756,875,1110,2020,2049,4001,4045 proto=udp
    litp create -t firewall-rule 		-p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfstcp 	-o 'name=001 nfstcp' dport=53,111,662,756,875,1110,2020,2049,4001,4045 proto=tcp
done

#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_A -o ipaddress=2001:4860:0:1001::68 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.10.10.1 position=2
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_C -o ipaddress=10.44.86.14 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.14 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n1/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

litp create -t dns-client -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.10.10.1 position=1
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_B -o ipaddress=10.44.86.14 position=2
litp create -t nameserver -p /deployments/d1/clusters/c1/nodes/n2/configs/dns_client/nameservers/my_name_server_C -o ipaddress=2001:4860:0:1001::68 position=3

#Sysparms
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_thresh_ipv4_3 -o key=net.ipv4.neigh.default.gc_thresh3 value=2048
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_thresh_ipv6_3 -o key=net.ipv6.neigh.default.gc_thresh3 value=2048
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl1 -o key=kernel.core_pattern value=/tmp/core.%e.pid%p.usr%u.sig%s.tim%t 
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_MS01 -o key=net.ipv4.udp_mem                      value="24794401 33059201 49588801"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_MS02 -o key=net.ipv6.route.mtu_expires            value=599
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_MS03 -o key=net.ipv6.conf.eth2.max_desync_factor  value=599 


     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl/params/sysctl_mn2_01       -o key=net.ipv6.conf.bond0.router_solicitation_interval value=5
     litp create -t sysparam             -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl/params/sysctl_mn1_01       -o key=net.ipv6.neigh.eth4/4.base_reachable_time_ms         value="29999"

#log rotate rules
litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate
litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n1/configs/logrotate/rules/messages -o name="a_messages" path="/var/log/messages" size=10M mail=ruth.evans@ammeon.com rotate=50 copytruncate=true

litp create -t logrotate-rule-config -p /ms/configs/logrotate
litp create -t logrotate-rule -p /ms/configs/logrotate/rules/messages -o name="a_messages" path="/var/log/messages" size=10M mail=ruth.evans@ammeon.com rotate=50 copytruncate=true

#repos
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://"${ms_host}"/6/os/x86_64/HighAvailability"
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo

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

# lsb service
x=0
pkg[x]="luci";       rel[x]="93.el6";     ver[x]="0.26.0";     VIP_count[x]=4;      active[x]=1; standby[x]=1 status_interval[x]=10   status_timeout[x]=10    restart_limit[x]=0      startup_retry_limit[x]=0     node_list[x]="n1,n2" initial_online_dependency_list[x]="test_service,httpd,ricci,cups" x=$[$x+1]
pkg[x]="httpd";      rel[x]="69.el6";     ver[x]="2.2.15";     VIP_count[x]=$[5*2]; active[x]=2; standby[x]=0 status_interval[x]=20   status_timeout[x]=30    restart_limit[x]=30     startup_retry_limit[x]=40    node_list[x]="n2,n1" initial_online_dependency_list[x]="cups" x=$[$x+1]
pkg[x]="test_service";    rel[x]="1";  ver[x]="1.0";      VIP_count[x]=$[0*2]; active[x]=1; standby[x]=1 status_interval[x]=20   status_timeout[x]=30    restart_limit[x]=30     startup_retry_limit[x]=40    node_list[x]="n2,n1" initial_online_dependency_list[x]="ricci,httpd" x=$[$x+1]
pkg[x]="cups";       rel[x]="79.el6";     ver[x]="1.4.2";      VIP_count[x]=3;      active[x]=1; standby[x]=1 status_interval[x]=40   status_timeout[x]=30    restart_limit[x]=3      startup_retry_limit[x]=2     node_list[x]="n2,n1" initial_online_dependency_list[x]="ricci" x=$[$x+1]
pkg[x]="ricci";      rel[x]="87.el6";     ver[x]="0.16.2";     VIP_count[x]=$[2*2]; active[x]=2; standby[x]=0 status_interval[x]=1000 status_timeout[x]=1000  restart_limit[x]=1000   startup_retry_limit[x]=1000  node_list[x]="n1,n2" x=$[$x+1]


vip_count=1
for (( x=0; x<${#pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${pkg[$x]}" -o name="${pkg[$x]}" version="${ver[$x]}" release="${rel[$x]}"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/"${pkg[$x]}" -o active="${active[$x]}" standby="${standby[$x]}" name=vcs_"${pkg[$x]}" online_timeout=45 offline_timeout=45 node_list="${node_list[$x]}" initial_online_dependency_list="${pkg[$x-1]}"
litp create -t service  -p /software/services/"${pkg[$x]}"   -o service_name="${pkg[$x]}"
litp inherit            -p /software/services/"${pkg[$x]}"/packages/pkg1 -s /software/items/"${pkg[$x]}"
litp inherit            -p /deployments/d1/clusters/c1/services/"${pkg[$x]}"/applications/"${pkg[$x]}" -s /software/services/"${pkg[$x]}"
        for (( i=0; i<${VIP_count[x]}; i++ )); do
                litp create -t vip   -p /deployments/d1/clusters/c1/services/"${pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
                litp create -t vip   -p /deployments/d1/clusters/c1/services/"${pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip_ipv6[$vip_count]}" network_name=traffic2
               vip_count=($vip_count+1)
        done
done

litp update -p /deployments/d1/clusters/c1/services/luci -o initail_online_dependency_list=


for (( i=1; i<10; i++ )); do
    litp create -t package -p /software/items/pkg_lsb$i -o name=EXTR-lsbwrapper$i
    litp create -t  service -p /software/services/service$i -o service_name=test-lsb-0$i
    litp inherit -p /software/services/service$i/packages/pkg$i -s /software/items/pkg_lsb$i
    litp inherit -p /deployments/d1/clusters/c1/services/luci/applications/luci_service$i -s /software/services/service$i
    litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/luci/ha_configs/service$(($i))_conf -o fault_on_monitor_timeouts=1 tolerance_limit=3 clean_timeout=70 status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 service_id=luci_service$i dependency_list=luci_service$(($i-1))

done;

litp update -p /deployments/d1/clusters/c1/services/luci/ha_configs/service1_conf -o dependency_list=
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/luci/ha_configs/luci_conf -o fault_on_monitor_timeouts=1 tolerance_limit=3 clean_timeout=70 status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 service_id=luci

for (( i=10; i<16; i++ )); do
    litp create -t package -p /software/items/pkg_lsb$i -o name=EXTR-lsbwrapper$i
    litp create -t  service -p /software/services/service$i -o service_name=test-lsb-$i
    litp inherit -p /software/services/service$i/packages/pkg$i -s /software/items/pkg_lsb$i
    litp inherit -p /deployments/d1/clusters/c1/services/test_service/applications/test_service$i -s /software/services/service$i
    litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/test_service/ha_configs/service$(($i))_conf -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 service_id=test_service$i dependency_list=test_service$(($i-1))

done;

litp update -p /deployments/d1/clusters/c1/services/test_service/ha_configs/service10_conf -o dependency_list=
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/httpd/ha_configs/conf -o fault_on_monitor_timeouts=1 tolerance_limit=3 clean_timeout=70 status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2

litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/test_service/ha_configs/test_service_conf -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2 service_id=test_service


# Add VxVM FS to F/O SG
litp inherit -p /deployments/d1/clusters/c1/services/cups/filesystems/fs1     -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_1/file_systems/VxVM_VG3_1 
litp inherit -p /deployments/d1/clusters/c1/services/cups/filesystems/fs2     -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_2/file_systems/VxVM_VG3_2 
litp inherit -p /deployments/d1/clusters/c1/services/luci/filesystems/fs3     -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_3/file_systems/VxVM_VG3_3 
litp inherit -p /deployments/d1/clusters/c1/services/luci/filesystems/fs4     -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_4/file_systems/VxVM_VG3_4 
litp inherit -p /deployments/d1/clusters/c1/services/luci/filesystems/fs5     -s /deployments/d1/clusters/c1/storage_profile/sp3/volume_groups/vg_vxvm_5/file_systems/VxVM_VG3_5 
litp inherit -p /deployments/d1/clusters/c1/services/luci/filesystems/fs7     -s /deployments/d1/clusters/c1/storage_profile/sp5/volume_groups/vg_vxvm_0_snap/file_systems/No_snap 
litp inherit -p /deployments/d1/clusters/c1/services/test_service/filesystems/fs1  -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vg_vxvm_0/file_systems/VxVM_VG2_1

# Add Package Lists
litp create -t package-list -p /software/items/pkg_list_empty -o name=pkg_list_empty
litp create -t package-list -p /software/items/pkg_list_populated -o name=pkg_list_populated

# Add Packages to package list
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-azerbaijani-in-ear -o name=3PP-azerbaijani-in-ear
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-czech-hello -o name=3PP-czech-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-dutch-hello -o name=3PP-dutch-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-ejb-in-ear -o name=3PP-ejb-in-ear
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-english-hello -o name=3PP-english-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-esperanto-in-ear -o name=3PP-esperanto-in-ear
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-finnish-hello -o name=3PP-finnish-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-french-hello -o name=3PP-french-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-french-in-ear -o name=3PP-french-in-ear
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-german-hello -o name=3PP-german-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-german-in-ear -o name=3PP-german-in-ear
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-helloworld -o name=3PP-helloworld
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-hungarian-in-ear -o name=3PP-hungarian-in-ear
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-irish-hello -o name=3PP-irish-hello
litp create -t package -p /software/items/pkg_list_populated/packages/3PP-irish-in-ear -o name=3PP-irish-in-ear

# Import the directory containing the 3PP packages to /var/www/html/
litp import /tmp/helloapps /var/www/html/hello_packages
litp create -p /software/items/hello_packages -t yum-repository -o name=hello_packages ms_url_path=/hello_packages

# Inherit Package list onto ms
litp inherit -p /ms/items/pkg_list_empty_ms -s /software/items/pkg_list_empty
litp inherit -p /ms/items/pkg_list_populated_ms -s /software/items/hello_packages
# Inherit Package lists onto nodes
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/pkg_list_empty_node1 -s /software/items/pkg_list_empty
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/pkg_list_populated -s /software/items/hello_packages
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/pkg_list_empty_node2 -s /software/items/pkg_list_empty
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/pkg_list_populated -s /software/items/hello_packages

# Add Packages
litp create -t yum-repository -p /software/items/new_repo_id -o name='new_repo_name' ms_url_path=/newRepo_dir
litp import /tmp/test_service-1.0-1.noarch.rpm /var/www/html/newRepo_dir/


litp inherit -p /ms/items/new_repo_id  -s /software/items/new_repo_id
litp inherit -p /ms/items/test_service -s /software/items/test_service

# Diff name service
litp create -p /software/items/diff_name_pkg -t package -o name="test_service_name-2.0-1"
litp create -p /software/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /software/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg
litp create -p /ms/services/diff_name_srvc -t service -o service_name="diff_service"
litp inherit -p /ms/services/diff_name_srvc/packages/diff_name_pkg -s /software/items/diff_name_pkg
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/diff_name_srvc -s /software/services/diff_name_srvc
#litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/diff_name_srvc -s /software/services/diff_name_srvc

# Create packages 
litp create -t package -p /software/items/jdk         	   -o name=jdk
litp create -t package -p /software/items/cups-libs        -o name=cups-libs   version=1.4.2  release=79.el6
litp create -t package -p /software/items/httpd-tools      -o name=httpd-tools version=2.2.15 release=69.el6
litp create -t package -p /software/items/libguestfs-tools-c -o name=libguestfs-tools-c
litp create -t package -p /software/items/tree -o name=tree
litp create -t package -p /software/items/unzip -o name=unzip

litp inherit -p /ms/items/java -s /software/items/jdk
for (( i=0; i<2; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java             -s /software/items/jdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools      -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs        -s /software/items/cups-libs
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/libguestfs-tools-c -s /software/items/libguestfs-tools-c
 #LITPCDS-11129
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/new_repo_id      -s /software/items/new_repo_id       # REPO

done;

# Update packages  LITPCDS-7747 

litp update -p /software/items/cups -o epoch=1
litp update -p /software/items/cups-libs -o epoch=1

# Sentinel
litp create -t package -p /software/items/sentinel -o name="EXTRlitpsentinellicensemanager_CXP9031488"
litp inherit -p /ms/items/sentinel -s /software/items/sentinel
litp create -t service -p /ms/services/sentinel -o service_name="sentinel"
litp create -t service -p /software/services/sentinel -o service_name="sentinel"
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

# Create md5 checksum
/usr/bin/md5sum /var/www/html/images/rhel7_image.qcow2     | cut -d ' ' -f 1 > /var/www/html/images/rhel7_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/base_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/base_image.qcow2.md5

x=0
x=$[$x+1] VM_cpu[x]=4; VM_ram[x]=2000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n1,n2" VM_dependency_list[x]="cups"      offline[x]="20"   eth0_ip[x]="${net898_ip_vm[0]}" eth1_ip[x]="${VM_net1vm_ip[1]}" eth2_ip[x]="${VM_net2vm_ip[1]}"
x=$[$x+1] VM_cpu[x]=4; VM_ram[x]=2000M; VM_active[x]=2; VM_standby[x]=0 VM_node_list[x]="n1,n2" VM_dependency_list[x]="id_vm$[$x+1]" offline[x]="50"   eth0_ip[x]="${net898_ip_vm[1]}","${net898_ip_vm[2]}" eth1_ip[x]="${VM_net1vm_ip[2]}","${VM_net1vm_ip[3]}" eth2_ip[x]="${VM_net2vm_ip[2]}","${VM_net2vm_ip[3]}"
x=$[$x+1] VM_cpu[x]=8; VM_ram[x]=4000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n2,n1" VM_dependency_list[x]="cups"      offline[x]="150"  eth0_ip[x]="${net898_ip_vm[3]}" eth1_ip[x]="${VM_net1vm_ip[4]}" eth2_ip[x]="${VM_net2vm_ip[4]}"
x=$[$x+1] VM_cpu[x]=8; VM_ram[x]=4000M; VM_active[x]=1; VM_standby[x]=1 VM_node_list[x]="n2,n1" VM_dependency_list[x]=               offline[x]="2000" eth0_ip[x]="${net898_ip_vm[4]}" eth1_ip[x]="${VM_net1vm_ip[5]}" eth2_ip[x]="${VM_net2vm_ip[5]}"
x=$[$x+1]

for (( i=1; i<=${#VM_cpu[@]}; i++ )); do
    litp create -t vm-image    -p /software/images/id_image$i -o name="image_vm$i" source_uri=http://"${ms_host}"/images/rhel7_image.qcow2
    litp create -t vm-service  -p /software/services/se_vm$i  -o service_name=vm$i image_name=image_vm$i  cpus="${VM_cpu[i]}" ram="${VM_ram[i]}" internal_status_check=on cleanup_command="/sbin/service vm$i force-stop" internal_status_check=off
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/updates -o name=vm_UPDATES base_url="http://${ms_host}/6/updates/x86_64/Packages"
    litp create -t vm-yum-repo -p /software/services/se_vm$i/vm_yum_repos/os -o name=vm_os base_url=http://${ms_ip}/6/os/x86_64
    litp create -t vm-alias -p /software/services/se_vm$i/vm_aliases/ms_alias -o alias_names=${ms_host},bossman address=${ms_ip}
    litp create -t vm-alias -p /software/services/se_vm$i/vm_aliases/ms_alias_IPV6 -o alias_names=ms address=fdde:4d7e:d471:1::835:66:a101
    litp create -t vm-alias -p /software/services/se_vm$i/vm_aliases/mn1_alias -o alias_names=node1,underling1 address=${node_ip[0]}
    litp create -t vm-alias -p /software/services/se_vm$i/vm_aliases/mn1_alias_IPV6 -o alias_names=ms address=fdde:4d7e:d471:1::835:66:a101
    litp create -t vm-alias -p /software/services/se_vm$i/vm_aliases/mn2_alias -o alias_names=node2,underling2 address=${node_ip[1]}
    litp create -t vm-alias -p /software/services/se_vm$i/vm_aliases/mm2_alias_IPV6 -o alias_names=ms address=fdde:4d7e:d471:1::835:66:a101
    litp create -t vm-package -p /software/services/se_vm$i/vm_packages/rhel_7_tree -o name=tree
    litp create -t vm-package -p /software/services/se_vm$i/vm_packages/rhel_7_unzip -o name=unzip
    litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/id_vm$i -o name=vm$i active="${VM_active[$i]}" standby="${VM_standby[$i]}" node_list="${VM_node_list[i]}" online_timeout=800
   litp create -t ha-service-config     -p /deployments/d1/clusters/c1/services/id_vm$i/ha_configs/conf1 -o status_interval=70 status_timeout=300 restart_limit=30 startup_retry_limit=40
   litp inherit                         -p /deployments/d1/clusters/c1/services/id_vm$i/applications/vm -s /software/services/se_vm$i
done

# Add TmpFs and RamFs to services
litp create -t vm-ram-mount -p /software/services/se_vm1/vm_ram_mounts/mount1 -o type=tmpfs mount_point="/mnt/data1" mount_options="size=512M,noexec,nodev,nosuid"
litp create -t vm-ram-mount -p /software/services/se_vm2/vm_ram_mounts/mount2 -o type=ramfs mount_point="/mnt/data2" mount_options="size=1024M,noexec,nodev,nosuid"
# Add vm-ssh-key to each of the 4 vms
litp create -t vm-ssh-key -p /software/services/se_vm1/vm_ssh_keys/key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAteGPA5/rZmaN9VV5lvGPIBmv4/LVAE8zVIUioPl//vPuWBRVNy4lTalqzb1Yg7pBx18P/MFq9gmuMo9y9bNR1pKuTccsCcH2TIUuLAPdEvoGymsF5h36ujig4cxlb79YlP9gtpSZ7j2ROkKTIiAf2d/mXtCltDY8MXwXEufrGykJ7LRTXGnYuezCshTCrvm7qcsGAyHSgHh8jtbNTUBq2VU0K5M6d4mfBm5qnfMLD9t2jFH7Zje643lO8T2oPdS9vJP/KcNfKR2UIy9o/aoVIDR9wxiARQ04R8BYJyxVxwPey0NJF3Zf6CayOJ27iOvO3ySyuGvCupKNnd4nvIe2QWjcGzlshWgMgAu0aE6kjF/32LbceDdVeLdV8Vhe46m5KiOI7dh2laV+ImT9eRaWlWciw1/Dd9f25Jx8ZbN/yd582su55mKpzrU3ANXb2STO46D+Y8RmDeWDY2pl7Mpe6h7yeMAArKUVhInTd7jUMWxvW2A/yDX4hJbZFRk5QaV8vP0FogQHowP2F1zmYXtf1RjztHQf9a/iCe4YpQsg0arGXYyEO3Z/2iZGyCLKSvCDZ/oI+cny6G5I96onpgXFYrEIw8PuN4K9+qt4LynQvuuezl8jlni5ig6Qv/KqdxMsqnxfktEizIjCsF414sDr98m5LHj10ksqC9KQD90Po50= Gary@localhost.localdomain"
litp create -t vm-ssh-key -p /software/services/se_vm2/vm_ssh_keys/key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAozjGMqo5p5f5XnMgMlymkpPEWRCoY5sq1QYJlTzOBn0A+SC4GVp6/gFujfH/TVYV8wXorCrhGvblHz34WlQIaLTil8fmqCnFrwvAqDctera+TxDSAWs7WhSuNjGXP4Ncn+aaMdgOUEhPukflnLmHBiuTJejXsMNLPmNLYiRBfJr39Ejgmx9ZMMz8zDnlhe2KvUIHc2+28TTRIj7sMy0nT4lwo8Cx5zzPrPP3KcXLJixhHVsSBqQlz7MrFv4F1UY7O3tp1TpQ2SgZhSinkOFXCqMUhtgmNg2uJ4RsLz82itur+UKIqmYXrJRyZsGkfg0p+TRhyVyLnyQHkJXNOaJB6e7+2Rvw2HnMS3m93Lw8IBWDmfk6Ejt4MNWHlEhkpBUHWFdUEZkgTZFef7ByCJcKy3lctjI5oxQJU8qtPHmMxMbgPz2wep/hLHQyKA5DmXzJkWR0vWaZ0ZOW3MOXNxmXNdWV48DalVliuzcZhBEuu5KhYW+AshDjGew+MrtbnBfd56/Ft1bF5BROD53BpQwAGkIizhVGhs9VQ/bst8hL/iKKyj+qDfudYnG+jC1FRC+fOO7PcbmLAG3mjoW4IpmXW0tvaeco0l3ANQdbxtEQewSivT3q4v+CMqG54Yd0u8sPLWdmxjs/JVkRh40NEbqLx2D6ckD/p5uEEPKS5899OAc= Gary@localhost.localdomain"
litp create -t vm-ssh-key -p /software/services/se_vm3/vm_ssh_keys/key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAt6drqzFsLi80WlPUXIrxI3qNUMQZUEcRcV67s0xPBaDbilEgJl0kow+RAIlTrS1Mb+tH4UdjuvsZ8X4g17PnokEszbtXF7LLYtu+ynPZqBydNRqF+ZFI+J/ku636FfoGEyFuo7apvEXYIj4pQj+YJWCv/fQ+PIvyI96zaAVxynKdYyUJQ08iGze94tJ4R0ublwrohNhe/mPmqOMrWL8v/4GKfVfiqmtD+0QvykwigCVUShDUHYmLl1jnAQ8UIX4I4vzGcP9mbQ3oTTYiuPmEeK96GO6aLdYtruXjK1bNcN8wGn0LdtqZ1S6XUaZRaobExIfxT8lAv8v7M0XeM86kI4J4f94Ff3YKt7HYcFcIh8/pLa9ZyhyvPTd4LrQgYw8Avk0Rwf5fkSAN2yVyoLVRBrfDi7n6zhmAIJJRr+zea85F1OAOmxv0OycoFGYeSgShIW+aA5zOnLtdx5Ob2CJVmu3dqA9Ga5ZzgTk8TcJ1O8Yi1SLP46Bj9v+5yopoIjbWme4EfUPDhfaV9P6VEB9x307sxDT/Z/M9PG7O+afqOFCb7BLrUQfUxzaaCPX2ZAMpXMbtmeQSl4Tgko37ZyEeaE5fRRD9LmfNI5DMdqbySqaS1AD5hUT2cRsQTArsvF8x0FM+GRTyLvnHztoNQZ63QNL2AUCGtGWJFEeXnGddYVc= Gary@localhost.localdomain"
litp create -t vm-ssh-key -p /software/services/se_vm4/vm_ssh_keys/key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEA0LumZOGh/7Wo/QJGAlej+tJ/dYwJ61rxoYEAcCAe2YglK6DY+/fA+yC1gDplCyF7dTzBCTYdqf++B40d1/kZ5lD5bRJRMrSMfZtosUSUg4iAp4CH9zYPoN7BQhsmMRtsoXzWG9YpxvbgG5NvsvzGKVT5Lc8eAkT3kw6wwbI6kdyV1GJLUgakiDgNkUANqwbKdlQmodliGsq4Be4ZsPlDofZBPuuEAwunZNto30rQgvR7V5GUjj2pjWy4m+49rLGXhEv7S2RBoCMUnMrqFC31cHTNoB7KxXL9DP4aYgBXeGpURdS90zNgE6glVS/AuHl5H+Ao5T9c9eXECRVTIhBcibAO75no2QKuhou5r3Gmi9o9O0tIU2YP+7NH+/4MeVg4+JhPxZX+okDngVbhDU2TZCHdfcIEO8VSS/tyit2NJnCXqrqzuxPYa6g5byY2AggAkAh8tuWjqyRCQjTFvyh4e6sxKheaslN82a2ZV/41Y8u/Rs0Fz6WCnnmIjXCKvmg/l4E60G7FpqCM2KMasWiJgVJ5SPkSb18+b9E9OaPpEJy/o4aiZtMuadp6ctmVtmOx5IwZYX8MazSQJKQ9PcHx0r53NZQmxPNJsLHiG+jON3SDbDB2HuHyRoFqD5TwEtGPfBDFRrAcjGeixavwN8WYEAZW953GwmexzVpBC3SXtEs= Gary@localhost.localdomain"

# Add VCS_Trigger to SGs
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/id_vm1/triggers/trig1 -o trigger_type=nofailover
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/cups/triggers/trig1 -o trigger_type=nofailover


litp update -p /software/images/id_image2 -o name="image_vm2" source_uri=http://"${ms_host}"/images/base_image.qcow2
litp update -p /software/images/id_image4 -o name="image_vm4" source_uri=http://"${ms_host}"/images/base_image.qcow2

litp create -t tag-model-item -p /software/items/snap_validation -o snapshot_tag=validation deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_validation -s /software/items/snap_validation
litp create -t tag-model-item -p /software/items/snap_sanitisation -o snapshot_tag=sanitisation deployment_tag=node
litp create -t tag-model-item -p /software/items/snap_san -o snapshot_tag=san deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_sanitisation -s /software/items/snap_sanitisation
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_san -s /software/items/snap_san

litp update -p /deployments/d1/clusters/c1/services/test_service/applications/test_service -o start_command="/etc/init.d/test_service.sh start" stop_command="/etc/init.d/test_service.sh stop" status_command="/etc/init.d/test_service.sh status"

# Node 3
litp create  -p /deployments/d1/clusters/c2  -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id_2}" app_agent_num_threads=9 default_nic_monitor=netstat


#litp create -t cluster -p /deployments/d1/clusters/c2
litp create -t node -p /deployments/d1/clusters/c2/nodes/n3 -o hostname="${node_hostname[2]}"
litp create -t blade -p /infrastructure/systems/sys4 -o system_name="${node_sysname[2]}"
litp create -t disk -p /infrastructure/systems/sys4/disks/disk0 -o name=hd0 size=38G bootable=true uuid="${node_disk1_uuid[2]}"
litp create -t bmc -p /infrastructure/systems/sys4/bmc -o ipaddress="${node_bmc_ip[2]}" username=root password_key=key-for-root

#Networking
litp create -t eth -p /deployments/d1/clusters/c2/nodes/n3/network_interfaces/n0 -o device_name=eth0 macaddress="${node_eth0_mac[2]}" network_name=mgmt ipaddress="${net835_ip[2]}"
litp create -t  eth -p /deployments/d1/clusters/c2/nodes/n3/network_interfaces/if2           -o device_name=eth2 macaddress="${node_eth2_mac[2]}" network_name=heartbeat1 rx_ring_buffer=2039 tx_ring_buffer=2039 txqueuelen=1250
litp create -t  eth -p /deployments/d1/clusters/c2/nodes/n3/network_interfaces/if3           -o device_name=eth3 macaddress="${node_eth3_mac[2]}" network_name=heartbeat2

litp create -t storage-profile -p /infrastructure/storage/storage_profiles/profile_21 
litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_21/volume_groups/vg1 -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_21/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=10G snap_size=50
litp create -p /infrastructure/storage/storage_profiles/profile_21/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G snap_size=50
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_21/volume_groups/vg1/physical_devices/pd1 -o device_name=hd0

litp inherit -p /deployments/d1/clusters/c2/nodes/n3/system -s /infrastructure/systems/sys4
litp inherit -p /deployments/d1/clusters/c2/nodes/n3/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c2/nodes/n3/storage_profile -s /infrastructure/storage/storage_profiles/profile_21 
litp inherit -p /deployments/d1/clusters/c2/nodes/n3/routes/route1 -s /infrastructure/networking/routes/route1 

# Cups SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c2/services/SG_cups -o deactivates=SG_new active=1 standby=0 name=vcs_cups online_timeout=300 offline_timeout=50 node_list=n3
litp inherit -p /deployments/d1/clusters/c2/services/SG_cups/applications/s1_cups -s /software/services/cups

# httpd SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c2/services/SG_httpd -o deactivates=SG_new active=1 standby=0 name=vcs_httpd online_timeout=300 offline_timeout=50 node_list=n3
litp inherit -p /deployments/d1/clusters/c2/services/SG_httpd/applications/s1_httpd -s /software/services/httpd
    

litp create_plan
