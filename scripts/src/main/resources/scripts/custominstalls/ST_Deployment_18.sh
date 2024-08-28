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
#function litp {
#    /usr/bin/litp "$@" || exit 
#}

litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://ms1/6/os/x86_64/HighAvailability"

litp import /tmp/lsb_pkg/EXTR-lsbwrapper1-2.0.0.rpm 3pp
litp import /tmp/lsb_pkg/EXTR-lsbwrapper2-2.0.0.rpm 3pp
litp import /tmp/test_service-1.0-1.noarch.rpm 3pp

# Plugin Install
for (( i=0; i<${#rpms[@]}; i++)); do
    # import plugin
    litp import "/tmp/${rpms[$i]}" litp
    # install plugin
    expect /tmp/root_yum_install_pkg.exp "${ms_host_short}" "${rpms[$i]%%-*}"
done

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${sfs_password}"

litp update -p /litp/logging -o force_debug=true

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment

#cluster_type used to be vcs, keep an eye on this
litp create -t vcs-cluster -p /deployments/d1/clusters/c1 -o cluster_type=sfha low_prio_net=net898 llt_nets=hb1,hb2 app_agent_num_threads=30  cluster_id="${vcs_cluster_id}" cs_initial_online=on default_nic_monitor=mii

litp create -p /ms/services/cobbler -o pxe_boot_timeout=360 -t cobbler-service

# SETUP THE MS DISKS
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"
litp create -p /infrastructure/systems/sys1/disks/disk0 -t disk -o name=hd0 size=20G bootable=true uuid="${ms_disk_uuid[0]}"
#litp create -p /infrastructure/systems/sys1/disks/disk1 -t disk -o name=hd1 size=20G bootable=false uuid="${ms_disk_uuid[1]}"

# STORAGE
# Storage Profile

# MS Storage Profile
#litp create -p /infrastructure/storage/storage_profiles/profile_ms -t storage-profile -o volume_driver=lvm
#litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1 -t volume-group -o volume_group_name=vg_group
#litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/file_systems/data -t file-system -o type=ext4 mount_point=/data_dir size=10G snap_size="5" snap_external="false"
#litp create -p /infrastructure/storage/storage_profiles/profile_ms/volume_groups/vg1/physical_devices/internal_hd1 -t physical-device -o device_name=hd1

#Cluster
#  LVM
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o volume_driver=lvm
# VG1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/nas -t physical-device -o device_name=hd0
#litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/additional1 -t physical-device -o device_name=hd5
## VG2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_images
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/vm_images -t file-system -o type=ext4 mount_point=/var/lib/libvirt/images size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd7
## VG3
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg3 -t volume-group -o volume_group_name=vg_instances
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg3/file_systems/vm_instances -t file-system -o type=ext4 mount_point=/var/lib/libvirt/instances size=15G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg3/physical_devices/internal -t physical-device -o device_name=hd9


##VXVM volumes
litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver=vxvm

litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1 -o volume_group_name=vxvg1
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/file_systems/fs1 -o type=vxfs size=2G mount_point=/vxvm_vol1 snap_size=80
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/physical_devices/pd0 -o device_name=hd1

litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg2 -o volume_group_name=vxvg2
litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg2/file_systems/fs1 -o type=vxfs size=200M mount_point=/vxvm_vol2 snap_size=20
litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg2/physical_devices/pd0 -o device_name=hd2

# VCS Cluster inherits the VXVM Profile 
litp inherit -p /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

#
#
#
#
# SETUP THE DISKS
# NODES
for (( i=0; i<2; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
#    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk5 -t disk -o name=hd5 size=1G bootable=false uuid="${node_disk_add1_uuid[$i]}"

#    # create shared disks for vxvm
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=10G bootable=false uuid="${vxvm_disk_uuid}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=400M bootable=false uuid="${vxvm2_disk_uuid}"
    #litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3 size=G bootable=false uuid="${vxvm_disk_uuid[2]}"
    #litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk4 -t disk -o name=hd4 size=5G bootable=false uuid="${vxvm_disk_uuid[3]}"

    # create disks for vm partions
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk7 -t disk -o name=hd7 size=8G bootable=false uuid="${vm_images_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk9 -t disk -o name=hd9 size=75G bootable=false uuid="${vm_instances_disk_uuid[$i]}"
done

## Setup the fencing disks to protect against VCS Split Brain
#litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o size=90M uuid="${fencing_disk_uuid[0]}" name=fd1
#litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o size=90M uuid="${fencing_disk_uuid[1]}" name=fd2
#litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o size=90M uuid="${fencing_disk_uuid[2]}" name=fd3


# Networking
litp create -p /infrastructure/networking/routes/r1 -t route -o subnet=0.0.0.0/0 gateway="${nodes_gateway}"
litp create -t route6  -p /infrastructure/networking/routes/route2_ipv6       -o subnet=::/0                 gateway="${ipv6_898_gw}"
#litp create -p /infrastructure/networking/routes/r2 -t route -o subnet="${route2_subnet}" gateway="${nodes_gateway}" 
#litp create -p /infrastructure/networking/routes/r3 -t route -o subnet="${route3_subnet}" gateway="${nodes_gateway}" 
#litp create -p /infrastructure/networking/routes/r4 -t route -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
#litp create -p /infrastructure/networking/routes/r5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_898}"
#litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet="${traf1gw_subnet}" gateway="${traf1_ip[1]}"
#litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet="${traf2gw_subnet}" gateway="${traf2_ip[1]}"


litp create -t network -p /infrastructure/networking/networks/mgmt -o name=net898 subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="${net1vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net2vm -o name=net2vm subnet="${net2vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net3vm -o name=net3vm subnet="${net3vm_subnet}"

litp create -t network -p /infrastructure/networking/networks/net837 -o name=net837 subnet="${net837_subnet}"
#litp create -t network -p /infrastructure/networking/networks/net837v6 -o name=net837v6
litp create -t network -p /infrastructure/networking/networks/hb1 -o name=hb1
litp create -t network -p /infrastructure/networking/networks/hb2 -o name=hb2
#litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"

#NTP
litp create -t ntp-service -p /software/items/ntp_ms
litp create -t ntp-server  -p /software/items/ntp_ms/servers/server0 -o server=127.127.1.0
litp create -t ntp-server  -p /software/items/ntp_ms/servers/server1 -o server=10.44.86.30
litp inherit -p /ms/items/ntp -s /software/items/ntp_ms

# MS
litp inherit -p /ms/system -s /infrastructure/systems/sys1
#litp inherit -p /ms/storage_profile -s /infrastructure/storage/storage_profiles/profile_ms


litp create -t alias-node-config -p /ms/configs/alias_config
litp create -t alias -p /ms/configs/alias_config/aliases/fwServer -o alias_names="fwServer","dot30","ciNode" address="10.44.86.30"
#ENM_DEP : Add 200+ aliases
for (( i=0; i<210; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/another_alias_$(($i+1)) -o alias_names=another-alias$(($i+1)) address="192.168.100."$(($i+10))
done
litp inherit -p /ms/routes/default_ipv6 -s /infrastructure/networking/routes/route2_ipv6
litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip_net898}" network_name=net898 ipv6address=$ipv6_898_tp$((ip6_898count++)) 
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}"
#litp create -t vlan -p /ms/network_interfaces/vlan898 -o device_name=eth1.898 ipaddress="${ms_ip_net898}" network_name=net898
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=eth1.837 ipaddress="${ms_ip_net837}" network_name=net837 ipv6address=$ipv6_837_tp$((ip6_837count++)) 
#litp create -t vlan -p /ms/network_interfaces/vlan94 -o device_name=eth1.94 ipaddress="${net1vm_ip_ms}" network_name=net1vm ipv6address=$ipv6_vm1_tp$((ip6_vm1count++)) 
litp create -t bridge -p /ms/network_interfaces/br0 -o network_name=net1vm ipaddress="${net1vm_ip_ms}" device_name=br0 multicast_snooping=0
litp create -t vlan -p /ms/network_interfaces/vlan94 -o device_name=eth1.94 bridge=br0 

litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}"


litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
#litp inherit -p /ms/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}" 
#litp inherit -p /ms/routes/r3 -s /infrastructure/networking/routes/r1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
#litp inherit -p /ms/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
#litp inherit -p /ms/routes/r5 -s /infrastructure/networking/routes/r5

#SysCtl Parameters
# MS
litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl01 -o key="fs.mqueue.msgsize_max" value="8200"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl02 -o key="dev.raid.speed_limit_min" value="1100"

litp update -p /ms -o hostname="$ms_host_short"

# REPOS
declare -a repo=("pkgApps" "pckglist1" "pckglist2" "pckglist3")
for i in ${repo[@]}
do
 litp import /var/www/html/$i /var/www/html/$i 

 litp create -t yum-repository -p /software/items/$i -o name=$i base_url=http://ms1/$i
 litp inherit -p /ms/items/$i -s /software/items/$i
done

# PACKAGES
declare -a pkg=("german" "czech" "dutch" "english" "french")
for j in ${pkg[@]}
do
 litp create -t package -p /software/items/$j -o name=3PP-$j-hello-1.0.0
 litp inherit -p /ms/items/$j -s /software/items/$j
done

declare -a pkglist=("plist1" "plist2" "plist3")
for a in ${pkglist[@]}
do
litp create -t package-list -p /software/items/$a -o name=$a version=1
litp inherit -p /ms/items/$a -s /software/items/$a
done

declare -a plist1=("italian" "polish" "klingon" "portuguese")
for b in "${plist1[@]}"
do
 litp create -t package -p /software/items/plist1/packages/$b -o name=3PP-$b-hello-1.0.0
done

declare -a plist2=("serbian" "russian" "romanian" "portuguese-hungarian-slovak")
for c in "${plist2[@]}"
do
 litp create -t package -p /software/items/plist2/packages/$c -o name=3PP-$c-hello-1.0.0
done

declare -a plist3=("spanish" "swedish" "finnish" "irish")
for d in "${plist3[@]}"
do
 litp create -t package -p /software/items/plist3/packages/$d -o name=3PP-$d-hello-1.0.0
done


# Nodes
for (( i=0; i<2; i++ )); do

     litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}" node_id="$(($i+1))"
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/default_ipv6 -s /infrastructure/networking/routes/route2_ipv6
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" master=bond0
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" master=bond0
     litp create -t bond -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond0 -o device_name=bond0 mode=1 miimon=150 ipaddress="${node_ip[$i]}" network_name=net898 ipv6address=$ipv6_898_tp$((ip6_898count++)) 
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[$i]}"
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" master=bond1
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" master=bond1
     litp create -t bond -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/bond1 -o device_name=bond1 mode=1 miimon=150
     litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[$i]}" network_name=traffic2 ipaddress="${traf2_ip[$i]}" ipv6address=$ipv6_t2_tp$((ip6_t2count++)) 

        litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/vlan_776 -o device_name=bond1.776 bridge=br1
        litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br1 -o device_name=br1 network_name=net1vm ipaddress="${br1_net1vm[$i]}" ipv6address=$ipv6_vm1_tp$((ip6_vm1count++)) multicast_snooping=0
        litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/vlan_777 -o device_name=bond1.777 bridge=br2
        litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br2 -o device_name=br2 network_name=net2vm ipaddress="${br2_net2vm[$i]}" ipv6address=$ipv6_vm2_tp$((ip6_vm2count++)) multicast_snooping=0
        litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/vlan_778 -o device_name=bond1.778 bridge=br3
        litp create -t bridge -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br3 -o device_name=br3 network_name=net3vm ipaddress="${br3_net3vm[$i]}" ipv6address=$ipv6_vm3_tp$((ip6_vm3count++)) multicast_snooping=0

     #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
     
     # Setup Network Hosts 
     litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traf2_nh${i} -o network_name=traffic2 ip="${traf2_ip[$i]}"


     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
     #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}"
     #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_898}"


     # SysCtl Params
     litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl01 -o key="kernel.threads-max" value="4132410"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl02 -o key="vm.dirty_background_ratio" value="11"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl03 -o key="debug.kprobes-optimization" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="5242880"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="5242880"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="655360"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="655360"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl05 -o key="vxvm.vxio.vol_failfast_on_write" value="2"
     litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm10 -o key=net.ipv4.ip_forward value=1

     # Log Rotation
     litp create -t logrotate-rule-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate
     litp create -t logrotate-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/msg_service$(($i+1)) -o name="msg_service" path="/var/log/messages" create=true rotate=15 rotate_every='month'

     #add repository to nodes
     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/yum_osHA_repo -s /software/items/yum_osHA_repo
done

litp create -t alias-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/NasServer -o alias_names="NasServer","SFS" address="10.44.86.231"


##### NAS #######
#MS
#managed SFS filesystems
#litpcrypt set key-for-sfs support support
litp create -t sfs-service -p /infrastructure/storage/storage_providers/68_storage_provider -o name="sfs-managed-68" management_ipv4="${sfs_management_ip}" user_name='support' password_key='key-for-sfs'
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/68_storage_provider/virtual_servers/vs_managed_68 -o name="sfs-managed-68" ipv4address="${sfs_vip}"
litp create -t sfs-pool -p /infrastructure/storage/storage_providers/68_storage_provider/pools/pl1 -o name=SFS_Pool
litp create -t sfs-cache -p /infrastructure/storage/storage_providers/68_storage_provider/pools/pl1/cache_objects/cache1 -o name='68Cache1'
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/68_storage_provider/pools/pl1/file_systems/fs1 -o size='100M' path='/vx/int_68_Managed-fs1' cache_name='68Cache1' snap_size='40'
litp create -t sfs-export -p /infrastructure/storage/storage_providers/68_storage_provider/pools/pl1/file_systems/fs1/exports/ex1 -o ipv4allowed_clients='10.44.86.200' options='rw,no_root_squash'
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/managed -o export_path="/vx/int_68_Managed-fs1" provider="sfs-managed-68" mount_point="/managed_mount_point" mount_options="soft" network_name="net837"

#unmanaged SFS shared file system 
litp create -t sfs-service -p /infrastructure/storage/storage_providers/68_unmanaged -o name="sfs-68"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/unmanaged -o export_path="/vx/int_68_unmanaged-fs1" provider="sfs-managed-68" mount_point="/unmanaged_mount_point" mount_options="soft" network_name="net837"

litp inherit -p /ms/file_systems/managed -s /infrastructure/storage/nfs_mounts/managed
litp inherit -p /ms/file_systems/unmanaged -s /infrastructure/storage/nfs_mounts/unmanaged


##### Firewalls #######
# MS
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp" provider=iptables
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_dnstcp -o 'name=200 dnstcp' dport=53 proto=tcp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_dnsudp -o 'name=201 dnsudp' dport=53 proto=udp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmpv6 -o 'name=101 icmpv6' proto=ipv6-icmp provider=ip6tables
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



## CLUSTER
litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp" provider=iptables
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_dnsudp -o 'name=201 dnsudp' dport=53 proto=udp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_vmhc -o name="300 vmhc" proto="tcp" dport=12987 provider=iptables
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmpv6 -o 'name=101 icmpv6' proto=ipv6-icmp provider=ip6tables


# VCS Service Groups
# CLUSTER 1 - VxVM 
# FAILOVER SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/apache -o active=1 standby=1 name=FO_SG1 online_timeout=90 offline_timeout=200 node_list=n1,n2 dependency_list=cupan_tae
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/apache/triggers/trigger -o trigger_type=nofailover
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/lucky_luci -o active=1 standby=1 name=FO_SG2 online_timeout=80 node_list=n2,n1
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/lucky_luci/triggers/dell -o trigger_type=nofailover
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/ricci -o active=1 standby=1 name=FO_SG3 online_timeout=70 node_list=n1,n2 dependency_list=flying_doves
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/ricci/triggers/rodney -o trigger_type=nofailover
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/flying_doves -o active=1 standby=1 name=FO_SG4 online_timeout=100 node_list=n2,n1 dependency_list=lucky_luci
litp create -t vcs-trigger -p /deployments/d1/clusters/c1/services/flying_doves/triggers/boycie -o trigger_type=nofailover

# PARALLEL SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/cupan_tae -o active=2 standby=0 name=PAR_SG1 online_timeout=70 offline_timeout=140 node_list=n1,n2 dependency_list=lucky_luci,ricci


## LSB RunTime (deprecated) - remove as soon as service version works (Pat Bohan 21/08/2015)
#litp create -t lsb-runtime  -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci -o name=risky_ricci service_name=ricci cleanup_command=/opt/ericsson/cleanup_ricci.sh status_interval=15 status_timeout=50 restart_limit=7
#
# LSB Services
litp create -t service -p /software/services/ricci -o service_name=ricci cleanup_command=/opt/ericsson/cleanup_ricci.sh
litp create -t service -p /software/services/httpd -o service_name=httpd cleanup_command=/opt/ericsson/cleanup_apache.sh
litp create -t service -p /software/services/testservice1 -o service_name="test-lsb-01"
litp create -t service -p /software/services/testservice2 -o service_name="test-lsb-02"
litp inherit -p /deployments/d1/clusters/c1/services/ricci/applications/ricci_service -s /software/services/ricci
litp inherit -p /deployments/d1/clusters/c1/services/apache/applications/httpd_service -s /software/services/httpd
litp inherit -p /deployments/d1/clusters/c1/services/apache/applications/testservice1 -s /software/services/testservice1
litp inherit -p /deployments/d1/clusters/c1/services/apache/applications/testservice2 -s /software/services/testservice2
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/ricci/ha_configs/conf_ricci -o status_interval=15 status_timeout=50 restart_limit=7
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/apache/ha_configs/conf_httpd1 -o status_interval=30 status_timeout=59 restart_limit=2 startup_retry_limit=3 tolerance_limit=2 clean_timeout=58 service_id=httpd_service dependency_list=testservice1,testservice2
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/apache/ha_configs/conf_httpd2 -o status_interval=30 status_timeout=70 restart_limit=3 startup_retry_limit=2 tolerance_limit=2 clean_timeout=70 service_id=testservice1 dependency_list=testservice2
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/apache/ha_configs/conf_httpd3 -o status_interval=30 status_timeout=60 restart_limit=2 startup_retry_limit=3 tolerance_limit=2 clean_timeout=60 service_id=testservice2

litp create -t service -p /software/services/cups -o service_name=cups cleanup_command=/opt/ericsson/wash_my_cup.sh
litp inherit -p /deployments/d1/clusters/c1/services/cupan_tae/applications/cups_service -s /software/services/cups
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/cupan_tae/ha_configs/conf_cups -o status_interval=45 status_timeout=45 restart_limit=4 startup_retry_limit=2 fault_on_monitor_timeouts=0


litp create -t service -p /software/services/luci -o service_name=luci cleanup_command=/opt/ericsson/cleanup_luci.sh
litp inherit -p /deployments/d1/clusters/c1/services/lucky_luci/applications/luci_service -s /software/services/luci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/lucky_luci/ha_configs/conf_luci -o status_interval=90 status_timeout=120 startup_retry_limit=5

litp create -t service -p /software/services/dovecot -o service_name=dovecot
litp inherit -p /deployments/d1/clusters/c1/services/flying_doves/applications/dovecot_service -s /software/services/dovecot


# Create a SW Package
# Versions are RHEL 6.6
litp create -t package -p /software/items/jdk -o name=jdk
litp create -t package -p /software/items/ricci -o name=ricci release=75.el6 version=0.16.2
litp create -t package -p /software/items/httpd -o name=httpd release=39.el6 version=2.2.15
litp create -t package -p /software/items/testpkg1 -o name=EXTR-lsbwrapper1
litp create -t package -p /software/items/testpkg2 -o name=EXTR-lsbwrapper2

litp inherit -p /software/services/ricci/packages/pkg1 -s /software/items/ricci
litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd
litp inherit -p /software/services/testservice1/packages/pkg1 -s /software/items/testpkg1
litp inherit -p /software/services/testservice2/packages/pkg2 -s /software/items/testpkg2

litp create -t package -p /software/items/luci -o name=luci release=63.el6 version=0.26.0
litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci

litp create -t package -p /software/items/dovecot -o name=dovecot release=7.el6_5.1 version=2.0.9 epoch=1
litp inherit -p /software/services/dovecot/packages/pkg1 -s /software/items/dovecot

litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1
litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups
litp inherit -p /ms/items/java -s /software/items/jdk

litp create -t package -p /software/items/libguestfs-tools -o name=libguestfs-tools
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/libguestfs-tools -s /software/items/libguestfs-tools
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/libguestfs-tools -s /software/items/libguestfs-tools

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/java -s /software/items/jdk
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/java -s /software/items/jdk

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=67.el6 epoch=1
for (( i=0; i<2; i++ )); do

  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs -s /software/items/cups-libs

done

## Mount a VxVM Volume on the FO SGs
litp inherit -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg3/file_systems/fs1
litp inherit -p /deployments/d1/clusters/c1/services/apache/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg1/file_systems/fs1
litp inherit -p /deployments/d1/clusters/c1/services/apache/filesystems/fs2 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg2/file_systems/fs1
litp inherit -p /deployments/d1/clusters/c1/services/flying_doves/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg4/file_systems/fs1
#
#
i## Create IP Resources

litp create -t vip -p /deployments/d1/clusters/c1/services/apache/ipaddresses/ip1 -o ipaddress="${traf2_vip[0]}" network_name=traffic2 ipaddress="$ipv6_t2_tp$((ip6_t2count++))/64"

litp create -t vip -p /deployments/d1/clusters/c1/services/lucky_luci/ipaddresses/ip1 -o ipaddress="${traf2_vip[1]}" network_name=traffic2 ipaddress="$ipv6_t2_tp$((ip6_t2count++))/64"

litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/ipaddresses/ip1 -o ipaddress="${traf2_vip[2]}" network_name=traffic2 ipaddress="$ipv6_t2_tp$((ip6_t2count++))/64"

# Sentinel
litp create -t package -p /software/items/sentinel -o name="EXTRlitpsentinellicensemanager_CXP9031488"
litp inherit -p /ms/items/sentinel -s /software/items/sentinel
litp create -t service -p /ms/services/sentinel -o service_name="sentinel"
litp create -t service -p /software/services/sentinel -o service_name="sentinel"
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

#VM services
# Create the md5 checksum file
/usr/bin/md5sum /var/www/html/images/vm_test_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/vm_test_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/test_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/test_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/enm_base_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/enm_base_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/enm_jboss_1.0.42.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/enm_jboss_1.0.42.qcow2.md5

# VM on the MS
litp create -t vm-image -p /software/images/ms_image -o name=msVM1 source_uri="http://ms1/images/vm_test_image.qcow2"
litp create -p /ms/services/ms_vmservice1 -t vm-service -o service_name="MSvmserv1" image_name="msVM1" cpus=2 ram=2000M internal_status_check=off
litp create -p /ms/services/ms_vmservice1/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br0 network_name=net1vm ipaddresses="${ms_vm_ip[0]}" gateway=${net1vm_gateway}
litp create -p /ms/services/ms_vmservice1/vm_aliases/stms -t vm-alias -o alias_names=stms address=${net1vm_ip_ms}
litp create -p /ms/services/ms_vmservice1/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_host}/6/os/x86_64"
litp create -p /ms/services/ms_vmservice1/vm_yum_repos/3pp -t vm-yum-repo -o name=3pp base_url="http://${ms_host}/3pp"
litp create -p /ms/services/ms_vmservice1/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${ms_host}/6/updates/x86_64/Packages"
litp create -p /ms/services/ms_vmservice1/vm_packages/wireshark -t vm-package -o name=wireshark
litp create -p /ms/services/ms_vmservice1/vm_packages/firefox -t vm-package -o name=firefox
litp create -p /ms/services/ms_vmservice1/vm_ssh_keys/sshkey1 -t vm-ssh-key -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9R6= key3@localhost.localdomain'

vm_num=20
for (( i=0; i<$vm_num; i++ )); do

   if [[ $(($i % 4)) -eq 0 ]]; then
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://ms1/images/vm_test_image.qcow2" #source_uri="http://ms1/images/enm_jboss_1.0.42.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=2 ram=4000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} force-stop-undefine"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='n1,n2' online_timeout=900 offline_timeout=400
      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=90 status_timeout=90 restart_limit=4 startup_retry_limit=2 clean_timeout=90 fault_on_monitor_timeouts=5

   elif [[ $(($i % 4)) -eq 1 ]]; then
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://ms1/images/vm_test_image.qcow2" #source_uri="http://ms1/images/enm_jboss_1.0.42.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=2 ram=4000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} stop-undefine --stop-timeout=60"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='n1,n2' online_timeout=900 offline_timeout=400
      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=90 status_timeout=90 restart_limit=4 startup_retry_limit=2 clean_timeout=90 fault_on_monitor_timeouts=5

   elif [[ $(($i % 4)) -eq 2 ]]; then
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://ms1/images/vm_test_image.qcow2" #source_uri="http://ms1/images/enm_base_image.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=2 ram=4000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} force-stop"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='n1,n2' online_timeout=900 offline_timeout=350
      litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=90 status_timeout=90 restart_limit=4 startup_retry_limit=2 clean_timeout=90 tolerance_limit=1

   else
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://ms1/images/vm_test_image.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=4 ram=2000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} stop-undefine"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_STvm${i} -o name="FO_vmSG${i}" active=1 standby=1 node_list='n2,n1' online_timeout=900
   fi


   # Setup networking
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic0 -o device_name=eth0 host_device=br1 network_name=net1vm
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic1 -o device_name=eth1 host_device=br2 network_name=net2vm
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic2 -o device_name=eth2 host_device=br3 network_name=net3vm
   litp inherit -p /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i} -s /software/services/vmservice${i}

   if [[ $(($i %4)) -eq 3 ]]; then
       #active-standy service - assign one IP
       #litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic0 -o ipaddresses="${vm_ip[$(($i*3+$j))]}" gateway=${net1vm_gateway}
       litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic0 -o ipaddresses="${vm_ip[$(($i*3))]}" ipv6addresses=$ipv6_vm1_tp$((ip6_vm1count++)) gateway6="${ipv6_vm1_gw}" 
       litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[$(($i*3+1))]}" ipv6addresses=$ipv6_vm2_tp$((ip6_vm2count++))
       litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic2 -o ipaddresses="${vm_ip[$(($i*3+2))]}" ipv6addresses=$ipv6_vm3_tp$((ip6_vm3count++))
   else
       #active-active service - assign two IPs
       #litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic0 -o ipaddresses="${vm_ip[$(($i*3+$j))]},${vm_ip[$(($vm_num+$i*3+$j))]}" gateway=${net1vm_gateway}
       litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic0 -o ipaddresses="${vm_ip[$(($i*3))]},${vm_ip[$(($vm_num*3+$i*3))]}" ipv6addresses=$ipv6_vm1_tp$((ip6_vm1count++)),$ipv6_vm1_tp$((ip6_vm1count++)) gateway6="${ipv6_vm1_gw}"
       litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[$(($i*3+1))]},${vm_ip[$(($vm_num*3+$i*3+1))]}" ipv6addresses=$ipv6_vm2_tp$((ip6_vm2count++)),$ipv6_vm2_tp$((ip6_vm2count++))
       litp update -p  /deployments/d1/clusters/c1/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic2 -o ipaddresses="${vm_ip[$(($i*3+2))]},${vm_ip[$(($vm_num*3+$i*3+2))]}" ipv6addresses=$ipv6_vm3_tp$((ip6_vm3count++)),$ipv6_vm3_tp$((ip6_vm3count++))
       
   fi


   # Add Aliases
   litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/ms1 -o alias_names=ms1,sky,rubble address=${net1vm_ip_ms}


   # Add REPOs
   litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/os -o name=os base_url="http://ms1/6/os/x86_64"
   litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/updates -o name=rhelPatches base_url="http://ms1/6/updates/x86_64/Packages"
   litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/3pp -o name=3pp base_url="http://ms1/3pp"

   # Add Packages
   litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/cups -o name=cups
   litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/jaws -o name=wireshark
   litp create -t vm-package -p  /software/services/vmservice${i}/vm_packages/test_service -o name=test_service
done

# Plugin Items
litp create -t tag-model-item -p /software/items/snap_validation -o snapshot_tag=validation deployment_tag=node
litp create -t tag-model-item -p /software/items/snap_sanitisation -o snapshot_tag=sanitisation deployment_tag=node
#litp create -t tag-model-item -p /software/items/snap_san -o snapshot_tag=san deployment_tag=node
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_validation -s /software/items/snap_validation
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_sanitisation -s /software/items/snap_sanitisation
#litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/snap_san -s /software/items/snap_san


#add aliases of all VM instances
for (( i=0; i<$vm_num; i++ )); do
       #active-active service - assign two IPs
       for (( j=0; j<$vm_num; j++)); do
	   if [[ $(($j %4)) -ne 3 ]]; then
              litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/STvm"${j}-n1" -o alias_names="STvm${j}-n1,STvm${j}-net1vm-n1" address="${vm_ip[$(($j*3))]}"
              litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/STvm"${j}-n2" -o alias_names="STvm${j}-n2,STvm${j}-net1vm-n2" address="${vm_ip[$(($vm_num*3+$j*3))]}"
	   else
              litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/STvm"${j}" -o alias_names="STvm${j},STvm${j}-net1vm" address="${vm_ip[$(($j*3))]}"
           fi
       done
done

# Add NFS Mounts to two VMs only (due to Network IP availability)
#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount1 -o mount_point="/mnt/cluster2a" mount_options="soft,defaults" device_path="nfs:/home/admin/ST/nfs_share_dir_72/dir_share_vm_1"
#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount2 -o mount_point="/mnt/cluster2b" mount_options="soft,defaults" device_path="nfs:/home/admin/ST/nfs_share_dir_72/dir_share_vm_2"




# Add some VM SG Dependencies
litp update -p /deployments/d1/clusters/c1/services/SG_STvm1 -o dependency_list=SG_STvm2,SG_STvm3  # FO SG dependent on FO and PL SG 
litp update -p /deployments/d1/clusters/c1/services/SG_STvm3 -o dependency_list=SG_STvm4           # PL SG dependent on PL SG
litp update -p /deployments/d1/clusters/c1/services/SG_STvm6 -o dependency_list=SG_STvm1,SG_STvm3  # PL SG dependent on FO and PL SG



## Add SSH Keys for some VMs ###
litp create -t vm-ssh-key -p /software/services/vmservice1/vm_ssh_keys/2048key -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv4Sc0ARARYN2uE1lbcIiBQhbKAHfBkWPh8Npz2QSbPCKKmVWa1KYHqUA0jBX16W0xEvlebhldP3+hb3K7+E29DN0fvG/i89qDhxxNrWZLV4gz6IK8CiGw1AgndOi3kUbK8+CzeHFXWbIyxq2xDyC8AVMIH8G86tVEEFNHar2uCGktvBJj/9h/pv86BWhka6kzANY70Dspg9TVnElFfWGpjbdYlxdYOr45IU0aGZoh7CO1FxuyROd7hHSSPeqPpiyQ5E7Rq0pP7vLJ/ztq4EJ0j58e3KGknFvArPIxXHvJiUbbfy2gCe9cKC83NoEL01mY3sMw7uQLpgah+/l2OWMNQ== Stephen@localhost.localdomain"

litp create -t vm-ssh-key -p /software/services/vmservice5/vm_ssh_keys/4096key2 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAqoh8OYzZ1Xy6YUisSq/MwzKCxjw1Dub2RobBL9kQWimGL7pyfJDb7VguA9YDBY2yf9lwLbP12ZZGVWnuD+2JXKTr6w+LhJLAfi1rHHlaDtcdFoZrmbV9+ZCSEbRvbpmu8qakIKqDZDZpcfJGWCXIMjaNmNeTa51Qw2/L1zVecy0c+7lHy26QaOmGGPqLrGy+MKBYgXi9SXfh+DYVcsTuisQcnACelTDdxVlB5FgL78To0DDRHHIme7zRMGkdg3wMR3PcerphNmbmBGny1z6FAS7U/eAPClsTaqF0LZPLb3wh1pbqGsgBEYo1LcV/PKtL0ejhZ+sc9Z4UCZG4JV0FyAIp7d1TzN1qWQ2SWo96gpDF1r8i4Hwe7NeOvVTu87yxSs400+tRrBGh8QWPWrQeeQylo04nK2VBTsQfD4hLc4DIwf0BaNPZdD4tovuPgr5N7ubzQLnCq6L4tsKKn55mZ3G549aonGScJeOItxKE+A6rIsrRbgT5+x3LYpgQIgzEv+2LIK3uPSP2hxLJ51QWunM6YW27YRdwVaElzFCpxYaS+kmygbjLBs2FFFE+uGSTR9JCoNCiZ1k6C+F+XOr/QPrJrzY2ekOHO8VAdD/feDcDQdz95hzBjF0JBcY5jfsOVn0M08d4je6fw+MeqhHCXVJRK4uQnb7/qu6D0ZtfF08= Stephen@localhost.localdomain"

litp create -t vm-ssh-key -p /software/services/vmservice6/vm_ssh_keys/4096key -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9I8= Stephen@localhost.localdomain"

# Update the hostname of a FO VM to a custom hostname
#litp update -p /deployments/d1/clusters/c1/services/SG_STvm2/applications/vmservice2 -o hostnames=rod


###############
# Add IPv6 sysctl parameters from node hardening document in 16B
##############

declare -a hardening=("net.ipv6.conf.default.autoconf" "net.ipv6.conf.default.accept_ra" "net.ipv6.conf.default.accept_ra_defrtr" "net.ipv6.conf.default.accept_ra_rtr_pref" "net.ipv6.conf.default.accept_ra_pinfo" "net.ipv6.conf.default.accept_source_route" "net.ipv6.conf.default.accept_redirects" "net.ipv6.conf.all.autoconf" "net.ipv6.conf.all.accept_ra" "net.ipv6.conf.all.accept_ra_defrtr" "net.ipv6.conf.all.accept_ra_rtr_pref" "net.ipv6.conf.all.accept_ra_pinfo" "net.ipv6.conf.all.accept_source_route" "net.ipv6.conf.all.accept_redirects")

c=1
for sys in ${hardening[@]}
do

 litp create -t sysparam -p /ms/configs/sysctl/params/hardening$c -o key=$sys value="0"
 for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/hardening$c -o key=$sys value="0"
 done
c=$(($c+1))

done



litp create_plan

