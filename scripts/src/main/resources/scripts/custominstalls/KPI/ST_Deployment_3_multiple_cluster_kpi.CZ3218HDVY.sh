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

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${sfs_password}"

/usr/bin/litp import /tmp/test_service-1.0-1.noarch.rpm 3pp

litp update -p /litp/logging -o force_debug=true

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://helios/6/os/x86_64/HighAvailability"
litp create -p /deployments/d1 -t deployment

litp create -t vcs-cluster -p /deployments/d1/clusters/c1 -o cluster_type=sfha low_prio_net=net834 llt_nets=hb1,hb2,hb3 cluster_id="${vcs_cluster_id}"
litp create -t vcs-cluster -p /deployments/d1/clusters/c2 -o cluster_type=vcs low_prio_net=net834 llt_nets=hb1,hb2 cluster_id="${vcs_cluster2_id}"

litp create -p /ms/services/cobbler -t cobbler-service

# STORAGE

# LVM Storage Profile
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o volume_driver=lvm  
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/additional1 -t physical-device -o device_name=hd5

# VXVM Storage Profile
litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver=vxvm
for (( i=1; i<5; i++ )); do
   litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg"$i" -o volume_group_name=vxvg"$i"
   litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg"$i"/file_systems/fs1 -o type=vxfs size=2G mount_point=/vxvm_vol"$i" snap_size=100
   litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg"$i"/physical_devices/pd0 -o device_name=hd"$i"
done

# VCS Cluster inherits the VXVM Profile 
litp inherit -p /deployments/d1/clusters/c1/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2


litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do

    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk5 -t disk -o name=hd5 size=1G bootable=false uuid="${node_disk_add1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root


    if [ "${cluster[$i]}" =  "1" ]; then 
        litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=5G bootable=false uuid="${vxvm_disk_uuid[0]}"
        litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=5G bootable=false uuid="${vxvm_disk_uuid[1]}"
        litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3 size=5G bootable=false uuid="${vxvm_disk_uuid[2]}"
        litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk4 -t disk -o name=hd4 size=5G bootable=false uuid="${vxvm_disk_uuid[3]}"
    fi

done


# Setup the fencing disks to protect against VCS Split Brain
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd1 -o size=90M uuid="${fencing_disk_uuid[0]}" name=fd1
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd2 -o size=90M uuid="${fencing_disk_uuid[1]}" name=fd2
litp create -t disk -p /deployments/d1/clusters/c1/fencing_disks/fd3 -o size=90M uuid="${fencing_disk_uuid[2]}" name=fd3


# Networking
litp create -p /infrastructure/networking/routes/r1 -t route -o subnet=0.0.0.0/0 gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r2 -t route -o subnet="${route2_subnet}" gateway="${nodes_gateway}" 
litp create -p /infrastructure/networking/routes/r3 -t route -o subnet="${route3_subnet}" gateway="${nodes_gateway}" 
litp create -p /infrastructure/networking/routes/r4 -t route -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/r5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_898}"
litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet="${traf1gw_subnet}" gateway="${traf1_ip[1]}"
litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet="${traf2gw_subnet}" gateway="${traf2_ip[1]}"

litp create -t route6 -p /infrastructure/networking/routes/default_ipv6 -o subnet=::/0 gateway="${ipv6_835_gateway}"
litp create -t route6 -p /infrastructure/networking/routes/ipv6_r1 -o subnet="${ipv6_836_network}" gateway="${ipv6_834_gateway}"
litp create -t route6 -p /infrastructure/networking/routes/ipv6_r2 -o subnet="${ipv6_dummy_network}" gateway="${ipv6_traf2_gateway}"

litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/net898 -o name=net898 subnet="${nodes_subnet_898}"
litp create -t network -p /infrastructure/networking/networks/net834 -o name=net834
litp create -t network -p /infrastructure/networking/networks/net836 -o name=net836 subnet="${nodes_subnet_836}"
litp create -t network -p /infrastructure/networking/networks/net837 -o name=net837 subnet="${nodes_subnet_837}"
litp create -t network -p /infrastructure/networking/networks/net837v6 -o name=net837v6
litp create -t network -p /infrastructure/networking/networks/hb1 -o name=hb1
litp create -t network -p /infrastructure/networking/networks/hb2 -o name=hb2
litp create -t network -p /infrastructure/networking/networks/hb3 -o name=hb3
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"
litp create -t network -p /infrastructure/networking/networks/net1vm -o name=net1vm subnet="${net1vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net2vm -o name=net2vm subnet="${net2vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net3vm -o name=net3vm subnet="${net3vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/net4vm -o name=net4vm subnet="${net4vm_subnet}"

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp create -t alias-node-config -p /ms/configs/alias_config
litp create -t alias -p /ms/configs/alias_config/aliases/fwServer -o alias_names="fwServer","dot30","ciNode" address="10.44.86.30"

litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond55
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bond55
litp create -t bond -p /ms/network_interfaces/b55 -o device_name=bond55 mode=1 miimon=150
litp create -t vlan -p /ms/network_interfaces/vlan835 -o device_name=bond55.835 ipaddress="${ms_ip}" ipv6address="${ms_ipv6}" network_name=mgmt
litp create -t vlan -p /ms/network_interfaces/vlan898 -o device_name=bond55.898 ipaddress="${ms_ip_898}" network_name=net898
litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=bond55.834 ipv6address="${ms_ipv6_834}" network_name=net834
litp create -t vlan -p /ms/network_interfaces/vlan836 -o device_name=bond55.836 ipaddress="${ms_ip_836}" network_name=net836
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=bond55.837 ipaddress="${ms_ip_837}" network_name=net837
litp create -t eth -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t vlan -p /ms/network_interfaces/vlan2_911 -o device_name=eth2.911 bridge=br2_911
litp create -t bridge -p /ms/network_interfaces/br2_911 -o device_name=br2_911 network_name=net1vm ipaddress="${net1vm_ip_ms}"
litp create -t vlan -p /ms/network_interfaces/vlan2_777 -o device_name=eth2.777 bridge=br2_777
litp create -t bridge -p /ms/network_interfaces/br2_777 -o device_name=br2_777 network_name=net3vm ipaddress="${net3vm_ip_ms}"
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}"
litp create -t vlan -p /ms/network_interfaces/vlan3_922 -o device_name=eth3.922 bridge=br3_922
litp create -t bridge -p /ms/network_interfaces/br3_922 -o device_name=br3_922 network_name=net2vm ipaddress="${net2vm_ip_ms}"
litp create -t vlan -p /ms/network_interfaces/vlan3_444 -o device_name=eth3.444 bridge=br3_444
litp create -t bridge -p /ms/network_interfaces/br3_444 -o device_name=br3_444 network_name=net4vm ipaddress="${net4vm_ip_ms}"


litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}" 
#litp inherit -p /ms/routes/r3 -s /infrastructure/networking/routes/r1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
#litp inherit -p /ms/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/r5 -s /infrastructure/networking/routes/r5
litp inherit -p /ms/routes/default_ipv6 -s /infrastructure/networking/routes/default_ipv6
litp inherit -p /ms/routes/ipv6_r1 -s /infrastructure/networking/routes/ipv6_r1

#SysCtl Parameters
# MS
litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl01 -o key="fs.mqueue.msgsize_max" value="8200"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl02 -o key="dev.raid.speed_limit_min" value="1100"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl03 -o key="net.ipv6.conf.bond55/898.regen_max_retry" value="6"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl04 -o key="net.ipv4.neigh.bond55/835.base_reachable_time_ms" value="30100"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="100000000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="100000000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="640000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="640000"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"


#Add Java Pck to MS
litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk
litp inherit -p /ms/items/java -s /software/items/openjdk

litp update -p /ms -o hostname="$ms_host_short"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
     litp create -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}" node_id="$(($i+1))"
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/os -s /software/profiles/os_prof1
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/items/java -s /software/items/openjdk
     litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" master=bond07
     litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth7_mac[$i]}" master=bond07
     litp create -t bond -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/bond07 -o device_name=bond07 mode=1 miimon=150 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6[$i]}" network_name=mgmt
     #litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan835 -o device_name=bond07.835 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6[$i]}" network_name=mgmt
     litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan837 -o device_name=bond07.837 ipv6address="${node_ipv6_837[$i]}" network_name=net837v6
     litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" ipv6address="${node_ipv6_834[$i]}" network_name=net834
     litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan1 -o device_name=eth1.898 ipaddress="${node_ip_898[$i]}" network_name=net898
     litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan2 -o device_name=eth1.836 ipaddress="${node_ip_836[$i]}" network_name=net836
     litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
     litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2

     if [ "${cluster[$i]}" =  "1" ]; then

        litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/items/yum_osHA_repo

        litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name=hb3
        litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[$i]}"
        litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan5 -o device_name=eth5.119 network_name=traffic1 ipaddress="${traf1_ip[$i]}" ipv6address="${traf1_ipv6[$i]}"
        litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[$i]}"
        litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan6 -o device_name=eth6.120 network_name=traffic2 ipaddress="${traf2_ip[$i]}" ipv6address="${traf2_ipv6[$i]}"
        litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
        litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw

        # Setup Network Hosts specific to cluster 1
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/traf1_nh${i} -o network_name=traffic1 ip="${traf1_ip[$i]}"
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/traf1_nh$(($i+4)) -o network_name=traffic1 ip="${traf1_nhipv6[$i]}"
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/traf2_nh${i} -o network_name=traffic2 ip="${traf2_ip[$i]}"
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/traf2_nh$(($i+4)) -o network_name=traffic2 ip="${traf2_nhipv6[$i]}"
 
        # Route specific to cluster 1
        litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/ipv6_r2 -s /infrastructure/networking/routes/ipv6_r2

    else

        # Network Interfaces specific to Cluster2
        litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[$i]}"
        litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan5_911 -o device_name=eth5.911 bridge=br5_911
        litp create -t bridge -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/br5_911 -o device_name=br5_911 network_name=net1vm ipaddress="${net1vm_ip[$i]}"
        litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan5_777 -o device_name=eth5.777 bridge=br5_777
        litp create -t bridge -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/br5_777 -o device_name=br5_777 network_name=net3vm ipaddress="${net3vm_ip[$i]}"

        litp create -t eth -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[$i]}"
        litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan6_922 -o device_name=eth6.922 bridge=br6_922
        litp create -t bridge -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/br6_922 -o device_name=br6_922 network_name=net2vm ipaddress="${net2vm_ip[$i]}"
        litp create -t vlan -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/vlan6_444 -o device_name=eth6.444 bridge=br6_444
        litp create -t bridge -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/network_interfaces/br6_444 -o device_name=br6_444 network_name=net4vm ipaddress="${net4vm_ip[$i]}"



        # Setup Network Hosts specific to cluster 2
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/net1vm_nh${i} -o network_name=net1vm ip="${net1vm_ip[$i]}"
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/net2vm_nh${i} -o network_name=net2vm ip="${net2vm_ip[$i]}"
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/net3vm_nh${i} -o network_name=net3vm ip="${net3vm_ip[$i]}"
        litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/net4vm_nh${i} -o network_name=net4vm ip="${net4vm_ip[$i]}"


    fi

     litp create -t vcs-network-host -p /deployments/d1/clusters/c${cluster[$i]}/network_hosts/net834_nh${i} -o network_name=net834 ip="${traf1_nhipv6[$i]}"
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/r2 -s /infrastructure/networking/routes/r1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}"
#     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/r3 -s /infrastructure/networking/routes/r1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
#     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/r4 -s /infrastructure/networking/routes/r1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/r5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_898}"
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/default_ipv6 -s /infrastructure/networking/routes/default_ipv6
     litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/routes/ipv6_r1 -s /infrastructure/networking/routes/ipv6_r1


     # SysCtl Params
     litp create -t sysparam-node-config -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl01 -o key="kernel.threads-max" value="4132410"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl02 -o key="vm.dirty_background_ratio" value="11"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl03 -o key="debug.kprobes-optimization" value="0"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl04 -o key="sunrpc.udp_slot_table_entries" value="15"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="100000000"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="100000000"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="640000"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="640000"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
     litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"


    if [ "${cluster[$i]}" =  "1" ]; then

          litp create -t sysparam -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/sysctl/params/sysctl05 -o key="vxvm.vxio.vol_failfast_on_write" value="2"

    fi

done

litp create -t alias-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/nodes/n1/configs/alias_config/aliases/NasServer -o alias_names="NasServer","SFS" address="${sfs_management_ip}"


##### NAS #######

## SFS
litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs_management_ip}" user_name="support" password_key="key-for-sfs" #pool_name="${sfs_pool}"
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"
litp create -t sfs-pool -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool -o name="${sfs_pool1}"
#litp create -t sfs-pool -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool -o name="${sfs_pool2}"
#litp create -t sfs-pool -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool -o name="${sfs_pool3}"

## Create file systems on the SFS
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_fs1 -o path="${sfs_prefix}-managedfs1" size="100M"
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_fs2 -o path="${sfs_prefix}-managedfs2" size="100M"
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_p2fs -o path="${sfs_prefix}-managedp2fs" size="100M"
litp create -t sfs-filesystem -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_p3fs -o path="${sfs_prefix}-managedp3fs" size="100M"

## Create managed shares on the SFS
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_fs1/exports/mg_ex1 -o ipv4allowed_clients="${ipv4_allowed_clients_all}" options="rw,no_root_squash"
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_fs2/exports/mg_ex2 -o ipv4allowed_clients="${ipv4_allowed_clients_nodes_c1}" options="ro,root_squash"
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_p2fs/exports/mg_p2exp -o ipv4allowed_clients="${ipv4_allowed_clients_ms}" options="rw,no_wdelay,no_root_squash"
litp create -t sfs-export -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool/file_systems/managed_p3fs/exports/mg_p3exp -o ipv4allowed_clients="${ipv4_allowed_clients_nodes_c2}" options="rw,no_wdelay,no_root_squash"


# Create the Mounts
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mg_mount1 -o export_path="${sfs_prefix}-managedfs1" provider="virtserv1" mount_point="/system72_mg" mount_options="soft,intr" network_name="${nas_network_ms_c2}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mg_mount2 -o export_path="${sfs_prefix}-managedfs1" provider="virtserv1" mount_point="/system72_mg" mount_options="soft,intr" network_name="${nas_network_c1}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mg_mount3 -o export_path="${sfs_prefix}-managedfs2" provider="virtserv1" mount_point="/cluster1_mg" mount_options="soft,intr" network_name="${nas_network_c1}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mg_mount4 -o export_path="${sfs_prefix}-managedp2fs" provider="virtserv1" mount_point="/ms72_mg" mount_options="soft,intr" network_name="${nas_network_ms_c2}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mg_mount5 -o export_path="${sfs_prefix}-managedp3fs" provider="virtserv1" mount_point="/cluster2_mg" mount_options="soft,intr" network_name="${nas_network_c1}"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/cluster1" mount_options="soft,intr" network_name="${nas_network_c1}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2 -o export_path="${sfs_prefix}-fs2" provider="virtserv1" mount_point="/cluster2" mount_options="soft,intr" network_name="${nas_network_c1}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountA -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/ms_share_sfs" mount_options="soft,intr" network_name="${nas_network_ms_c2}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountB -o export_path="${sfs_prefix}-fs2" provider="virtserv1" mount_point="/ms_share_sfs1" mount_options="soft,intr" network_name="${nas_network_ms_c2}"



## NFS
litp create -t nfs-service -p /infrastructure/storage/storage_providers/sp1 -o name="nfs1" ipv4address="${nfs_management_ip}"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount3 -o export_path="${nfs_prefix}/dir_share_72" provider="nfs1" mount_point="/cluster_share_nfs" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount4 -o export_path="${nfs_prefix}/dir_share_72_1" provider="nfs1" mount_point="/cluster_share_nfs1" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountC -o export_path="${nfs_prefix}/dir_share_72" provider="nfs1" mount_point="/ms_share_nfs" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountD -o export_path="${nfs_prefix}/dir_share_72_1" provider="nfs1" mount_point="/ms_share_nfs1" mount_options="soft,intr" network_name="mgmt"



#MS
litp inherit -p /ms/file_systems/mg_fs1 -s /infrastructure/storage/nfs_mounts/mg_mount1
litp inherit -p /ms/file_systems/mg_fs2 -s /infrastructure/storage/nfs_mounts/mg_mount4

litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mountA
litp inherit -p /ms/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mountB
litp inherit -p /ms/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mountC
litp inherit -p /ms/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mountD

#Nodes
#### Unmanaged Shares

for (( i=0; i<${#node_sysname[@]}; i++ )); do

# Unmanaged Shares
    litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
    litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount2
    litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mount3
    litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mount4

# Managed Shares
    # Both Clusters
    litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/mg_fs1 -s /infrastructure/storage/nfs_mounts/mg_mount2

    # Cluster Specific 
    if [ "${cluster[$i]}" =  "1" ]; then
       litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/mg_fs2 -s /infrastructure/storage/nfs_mounts/mg_mount3
    else
       litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/file_systems/mg_fs2 -s /infrastructure/storage/nfs_mounts/mg_mount5
    fi 

done


##### Firewalls #######
# MS
litp create -t firewall-node-config -p /ms/configs/fw_config
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp" provider=iptables
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_dnstcp -o 'name=200 dnstcp' dport=53 proto=tcp
litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_dnsudp -o 'name=201 dnsudp' dport=53 proto=udp



## CLUSTER
for (( i=1; i<3; i++ )); do

   litp create -t firewall-cluster-config -p /deployments/d1/clusters/c$i/configs/fw_config
   litp create -t firewall-rule -p /deployments/d1/clusters/c$i/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp" provider=iptables
   litp create -t firewall-rule -p /deployments/d1/clusters/c$i/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
   litp create -t firewall-rule -p /deployments/d1/clusters/c$i/configs/fw_config/rules/fw_dnsudp -o 'name=201 dnsudp' dport=53 proto=udp

done

# NODE
for (( i=0; i<${#node_sysname[@]}; i++ )); do

  litp create -t firewall-node-config -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/fw_config
  litp create -t firewall-rule -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
  litp create -t firewall-rule -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/fw_config/rules/fw_dnstcp -o 'name=200 dnstcp' dport=53 proto=tcp
  litp create -t firewall-rule -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables

done

### FW Rules specific to VM Cluster

   ## VM Healthcheck
   litp create -t firewall-rule -p /deployments/d1/clusters/c2/configs/fw_config/rules/fw_vmhc -o name="300 vmhc" proto="tcp" dport=12987 provider=iptables

   ## DHCP
   litp create -t firewall-rule -p /deployments/d1/clusters/c2/configs/fw_config/rules/fw_dhcp -o name="400 dhcp" proto="udp" dport=67 provider=iptables
   litp create -t firewall-rule -p /deployments/d1/clusters/c2/configs/fw_config/rules/fw_dhcp_sync -o name="401 dhcpsync" proto="tcp" dport=647 provider=iptables


###### DNS #####

# MS
litp create -t dns-client -p /ms/configs/dns_client -o search=openvpn.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/dns1 -o ipaddress=10.44.86.4 position=1

# NODES

for (( i=0; i<${#node_sysname[@]}; i++ )); do

litp create -t dns-client -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/dns_client -o search=openvpn.com
litp create -t nameserver -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/configs/dns_client/nameservers/dns1 -o ipaddress=fdde:4d7e:d471::834:4:4 position=1

done


# VCS Service Groups

# CLUSTER 1 - VxVM 

# FAILOVER SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/apache -o active=1 standby=1 name=FO_SG1 online_timeout=90 node_list=n1,n2 dependency_list=cupan_tae
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/lucky_luci -o active=1 standby=1 name=FO_SG2 online_timeout=80 node_list=n2,n1
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/ricci -o active=1 standby=1 name=FO_SG3 online_timeout=70 node_list=n1,n2 dependency_list=flying_doves
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/flying_doves -o active=1 standby=1 name=FO_SG4 online_timeout=100 node_list=n2,n1 dependency_list=lucky_luci

# PARALLEL SG
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/cupan_tae -o active=2 standby=0 name=PAR_SG1 online_timeout=70 node_list=n1,n2 dependency_list=lucky_luci,ricci


# LSB RunTime (deprecated)
litp create -t lsb-runtime  -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci -o name=risky_ricci service_name=ricci cleanup_command=/opt/ericsson/cleanup_ricci.sh status_interval=15 status_timeout=50 restart_limit=7

# LSB Services
litp create -t service -p /software/services/httpd -o service_name=httpd cleanup_command=/opt/ericsson/cleanup_apache.sh
litp inherit -p /deployments/d1/clusters/c1/services/apache/applications/httpd_service -s /software/services/httpd
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/apache/ha_configs/conf_httpd -o status_interval=30 status_timeout=59 restart_limit=2 startup_retry_limit=3


litp create -t service -p /software/services/cups -o service_name=cups cleanup_command=/opt/ericsson/wash_my_cup.sh
litp inherit -p /deployments/d1/clusters/c1/services/cupan_tae/applications/cups_service -s /software/services/cups
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/cupan_tae/ha_configs/conf_cups -o status_interval=45 status_timeout=45 restart_limit=4 startup_retry_limit=2


litp create -t service -p /software/services/luci -o service_name=luci cleanup_command=/opt/ericsson/cleanup_luci.sh
litp inherit -p /deployments/d1/clusters/c1/services/lucky_luci/applications/luci_service -s /software/services/luci
litp create -t ha-service-config -p /deployments/d1/clusters/c1/services/lucky_luci/ha_configs/conf_luci -o status_interval=90 status_timeout=120 startup_retry_limit=5


litp create -t service -p /software/services/dovecot -o service_name=dovecot
litp inherit -p /deployments/d1/clusters/c1/services/flying_doves/applications/dovecot_service -s /software/services/dovecot


# Create a SW Package
# Versions are RHEL 6.6
litp create -t package -p /software/items/ricci -o name=ricci release=75.el6 version=0.16.2
litp inherit -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/packages/pkg1 -s /software/items/ricci

litp create -t package -p /software/items/httpd -o name=httpd release=39.el6 version=2.2.15
litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd

litp create -t package -p /software/items/luci -o name=luci release=63.el6 version=0.26.0
litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci

litp create -t package -p /software/items/dovecot -o name=dovecot release=7.el6_5.1 version=2.0.9 epoch=1
litp inherit -p /software/services/dovecot/packages/pkg1 -s /software/items/dovecot

litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1
litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups

# Pin dependent packages to support version pinning of LSB Packages above
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=67.el6 epoch=1
for (( i=0; i<2; i++ )); do

  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs -s /software/items/cups-libs

done




#Create a SW Package
# Versions are RHEL 6.4
#litp create -t package -p /software/items/ricci -o name=ricci release=63.el6 version=0.16.2
#litp inherit -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/packages/pkg1 -s /software/items/ricci

#litp create -t package -p /software/items/httpd -o name=httpd release=29.el6_4 version=2.2.15
#litp create -t package -p /software/items/httpd -o name=httpd release=26.el6 version=2.2.15
#litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd

#litp create -t package -p /software/items/luci -o name=luci release=37.el6 version=0.26.0
#litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci

#litp create -t package -p /software/items/dovecot -o name=dovecot release=5.el6 version=2.0.9
#litp inherit -p /software/services/dovecot/packages/pkg1 -s /software/items/dovecot

#litp create -t package -p /software/items/cups -o name=cups release=50.el6_4.5 version=1.4.2
#litp create -t package -p /software/items/cups -o name=cups release=48.el6_3.3 version=1.4.2
#litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups

# Pin dependent packages to support version pinning of LSB Packages above
#litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=26.el6
#litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=48.el6_3.3
#for (( i=0; i<2; i++ )); do

#  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
#  litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs -s /software/items/cups-libs

#done

# Mount a VxVM Volume on the FO SGs
litp inherit -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg3/file_systems/fs1
litp inherit -p /deployments/d1/clusters/c1/services/apache/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg1/file_systems/fs1
litp inherit -p /deployments/d1/clusters/c1/services/apache/filesystems/fs2 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg2/file_systems/fs1
litp inherit -p /deployments/d1/clusters/c1/services/flying_doves/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/sp2/volume_groups/vxvg4/file_systems/fs1


# Create IP Resources
# FO SG1 #VIPs = #AC(1)........ 1 IPv4 VIP per Traffic1 Network, 1 IPv4 + 1 IPv6 VIP per Traffic2 Network
for (( i=1; i<2; i++ )); do

litp create -t vip -p /deployments/d1/clusters/c1/services/apache/ipaddresses/ip${i} -o ipaddress="${traf1_vip_ipv6[$i]}" network_name=traffic1
litp create -t vip -p /deployments/d1/clusters/c1/services/apache/ipaddresses/ip$(($i+1)) -o ipaddress="${traf2_vip[$i]}" network_name=traffic2
litp create -t vip -p /deployments/d1/clusters/c1/services/apache/ipaddresses/ip$(($i+2)) -o ipaddress="${traf2_vip_ipv6[$i]}" network_name=traffic2

done

# FO SG2 #VIPs = 3x #AC(1) .......3 IPv4 VIPs per Traffic1 Network, 3 IPv4 + 3 IPv6 VIPs per Traffic2 Network
for (( i=1; i<4; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/lucky_luci/ipaddresses/ip${i} -o ipaddress="${traf1_vip_ipv6[$(($i+1))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/lucky_luci/ipaddresses/ip$(($i+3)) -o ipaddress="${traf2_vip[$(($i+1))]}" network_name=traffic2
 litp create -t vip -p /deployments/d1/clusters/c1/services/lucky_luci/ipaddresses/ip$(($i+6)) -o ipaddress="${traf2_vip_ipv6[$(($i+1))]}" network_name=traffic2

done

# FO SG3 #VIPs = 5x #AC(1)......... 5 IPv4 VIPs per Traffic1 Network, 5 IPv4 + 5 IPv6 VIPs per Traffic2 Network
for (( i=1; i<6; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/ipaddresses/ip${i} -o ipaddress="${traf1_vip_ipv6[$(($i+4))]}"  network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/ipaddresses/ip$(($i+5)) -o ipaddress="${traf2_vip[$(($i+4))]}" network_name=traffic2
 litp create -t vip -p /deployments/d1/clusters/c1/services/ricci/runtimes/ricci/ipaddresses/ip$(($i+10)) -o ipaddress="${traf2_vip_ipv6[$(($i+4))]}" network_name=traffic2

done

# FO SG4 (dovecot) #VIPs = NONE

# PAR SG #VIPs = 3x #AC(4) ..........12 IPv4 VIPs per Traffic1 Network, 12 IPv4 + 12 IPv6 VIPs per Traffic2 Network
for (( i=1; i<13; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/c1/services/cupan_tae/ipaddresses/ip${i} -o ipaddress="${traf1_vip_ipv6[$(($i+9))]}" network_name=traffic1
 litp create -t vip -p /deployments/d1/clusters/c1/services/cupan_tae/ipaddresses/ip$(($i+12)) -o ipaddress="${traf2_vip[$(($i+9))]}" network_name=traffic2
 litp create -t vip -p /deployments/d1/clusters/c1/services/cupan_tae/ipaddresses/ip$(($i+24)) -o ipaddress="${traf2_vip_ipv6[$(($i+9))]}" network_name=traffic2

done

## Add the Sentinel service ##

# MS 
litp create -t package -p /software/items/sentinel -o name="EXTRlitpsentinellicensemanager_CXP9031488"
litp inherit -p /ms/items/sentinel -s /software/items/sentinel

litp create -t service -p /ms/services/sentinel -o service_name="sentinel"

# Nodes
litp create -t service -p /software/services/sentinel -o service_name="sentinel"
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

for (( i=0; i<${#node_sysname[@]}; i++ )); do

litp inherit -p /deployments/d1/clusters/c${cluster[$i]}/nodes/n$(($i+1))/services/sentinel -s /software/services/sentinel

done

# Cluster 2 - VMs

# Create the md5 checksum file
/usr/bin/md5sum /var/www/html/images/image_with_ocf.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/image_with_ocf.qcow2.md5
/usr/bin/md5sum /var/www/html/images/test_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/test_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/enm_base_image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/enm_base_image.qcow2.md5
/usr/bin/md5sum /var/www/html/images/enm_jboss_1.0.42.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/enm_jboss_1.0.42.qcow2.md5


for (( i=1; i<7; i++ )); do  

# 6 VMs
# Define 1st 2 VM SGs as FO SGs ............to keep in line ENM Deployment of only 2 FO SGs in the services cluster   

   # vm5 and vm6
   if (( $i > 4 )); then
#     litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://10.44.86.72/images/enm_jboss_1.0.42.qcow2"
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://helios/images/image_with_ocf.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=2 ram=4000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} force-stop"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c2/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='n3,n4' online_timeout=900
      litp create -t ha-service-config -p /deployments/d1/clusters/c2/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=90 status_timeout=90 restart_limit=4 startup_retry_limit=2

   # vm3 and vm4
   elif ( [[ $i > 2 ]] && [[ $i < 5 ]] ); then
#     litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://10.44.86.72/images/enm_base_image.qcow2"
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://helios/images/image_with_ocf.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=2 ram=4000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} force-stop"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c2/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='n3,n4' online_timeout=900
      litp create -t ha-service-config -p /deployments/d1/clusters/c2/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=90 status_timeout=90 restart_limit=4 startup_retry_limit=2
  
  # vm1 and vm2
   else
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://helios/images/image_with_ocf.qcow2"
      litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=4 ram=2000M internal_status_check=on cleanup_command="/sbin/service STvmserv${i} force-stop"
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/c2/services/SG_STvm${i} -o name="FO_vmSG${i}" active=1 standby=1 node_list='n4,n3' online_timeout=900
   fi
   litp inherit -p /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i} -s /software/services/vmservice${i}


   # Setup networking
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic0 -o device_name=eth0 host_device=br5_911 network_name=net1vm
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic1 -o device_name=eth1 host_device=br6_922 network_name=net2vm mac_prefix=22:22:22
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic2 -o device_name=eth2 host_device=br5_777 network_name=net3vm
   litp create -t vm-network-interface -p /software/services/vmservice${i}/vm_network_interfaces/vm_nic3 -o device_name=eth3 host_device=br6_444 network_name=net4vm

   if (($i > 2)); then #assign two IPs
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic0 -o ipaddresses="${vm_ip[$i]},${vm_ip[$(($i+16))]}" gateway=${net1vm_gateway}
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm2_ip[$i]},${vm2_ip[$(($i+16))]}"
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic2 -o ipaddresses="${vm3_ip[$i]},${vm3_ip[$(($i+16))]}"
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic3 -o ipaddresses="${vm4_ip[$i]},${vm4_ip[$(($i+16))]}"

   else
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic0 -o ipaddresses="${vm_ip[$(($i+32))]}" gateway=${net1vm_gateway}
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm2_ip[$(($i+32))]}" 
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic2 -o ipaddresses="${vm3_ip[$(($i+32))]}"
       litp update -p  /deployments/d1/clusters/c2/services/SG_STvm${i}/applications/vmservice${i}/vm_network_interfaces/vm_nic3 -o ipaddresses="${vm4_ip[$(($i+32))]}"

   fi

   # Add Aliases
   litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/dot75 -o alias_names=dot75,rocky,chase address=${net1vm_ip[2]}
   litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/dot76 -o alias_names=dot76,zuma,marshall address=${net1vm_ip[3]}
   litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/helios -o alias_names=helios,sky,rubble address=${net1vm_ip_ms}
   litp create -t vm-alias -p /software/services/vmservice${i}/vm_aliases/nfs_storage -o alias_names=nfs address="10.44.86.4"


   # Add REPOs
   litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/os -o name=os base_url="http://helios/6/os/x86_64"
   litp create -t vm-yum-repo -p /software/services/vmservice${i}/vm_yum_repos/updates -o name=rhelPatches base_url="http://10.46.83.2/6/updates/x86_64/Packages"

   # Add Packages
   # litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/cups -o name=cups
   # litp create -t vm-package -p /software/services/vmservice${i}/vm_packages/jaws -o name=wireshark

   # Add NFS Mounts - commented out until can setup access to the 834 network to mount them
   #litp create -t vm-nfs-mount -p /software/services/vmservice${i}/vm_nfs_mounts/mount1 -o mount_point="/mnt/cluster2a" mount_options="soft,defaults" device_path="nfs:/home/admin/ST/nfs_share_dir_72/dir_share_vm_1"
   #litp create -t vm-nfs-mount -p /software/services/vmservice${i}/vm_nfs_mounts/mount2 -o mount_point="/mnt/cluster2b" mount_options="soft,defaults" device_path="nfs:/home/admin/ST/nfs_share_dir_72/dir_share_vm_2"

done

##### extra package and repo for the VM E-2-E test in regression
   # litp create -t vm-package -p  /software/services/vmservice1/vm_packages/test_service -o name=test_service
   # litp create -t vm-yum-repo -p /software/services/vmservice1/vm_yum_repos/3pp -o name=3pp base_url="http://helios/3pp"

###################
## TEMP HARDCODING
##################
litp update -p /deployments/d1/clusters/c2/services/SG_STvm1 -o dependency_list=SG_STvm2,SG_STvm3
litp update -p /deployments/d1/clusters/c2/services/SG_STvm3 -o dependency_list=SG_STvm4


## Add SSH Keys for some VMs ###
litp create -t vm-ssh-key -p /software/services/vmservice1/vm_ssh_keys/2048key -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAv4Sc0ARARYN2uE1lbcIiBQhbKAHfBkWPh8Npz2QSbPCKKmVWa1KYHqUA0jBX16W0xEvlebhldP3+hb3K7+E29DN0fvG/i89qDhxxNrWZLV4gz6IK8CiGw1AgndOi3kUbK8+CzeHFXWbIyxq2xDyC8AVMIH8G86tVEEFNHar2uCGktvBJj/9h/pv86BWhka6kzANY70Dspg9TVnElFfWGpjbdYlxdYOr45IU0aGZoh7CO1FxuyROd7hHSSPeqPpiyQ5E7Rq0pP7vLJ/ztq4EJ0j58e3KGknFvArPIxXHvJiUbbfy2gCe9cKC83NoEL01mY3sMw7uQLpgah+/l2OWMNQ== Stephen@localhost.localdomain"

litp create -t vm-ssh-key -p /software/services/vmservice5/vm_ssh_keys/4096key2 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAqoh8OYzZ1Xy6YUisSq/MwzKCxjw1Dub2RobBL9kQWimGL7pyfJDb7VguA9YDBY2yf9lwLbP12ZZGVWnuD+2JXKTr6w+LhJLAfi1rHHlaDtcdFoZrmbV9+ZCSEbRvbpmu8qakIKqDZDZpcfJGWCXIMjaNmNeTa51Qw2/L1zVecy0c+7lHy26QaOmGGPqLrGy+MKBYgXi9SXfh+DYVcsTuisQcnACelTDdxVlB5FgL78To0DDRHHIme7zRMGkdg3wMR3PcerphNmbmBGny1z6FAS7U/eAPClsTaqF0LZPLb3wh1pbqGsgBEYo1LcV/PKtL0ejhZ+sc9Z4UCZG4JV0FyAIp7d1TzN1qWQ2SWo96gpDF1r8i4Hwe7NeOvVTu87yxSs400+tRrBGh8QWPWrQeeQylo04nK2VBTsQfD4hLc4DIwf0BaNPZdD4tovuPgr5N7ubzQLnCq6L4tsKKn55mZ3G549aonGScJeOItxKE+A6rIsrRbgT5+x3LYpgQIgzEv+2LIK3uPSP2hxLJ51QWunM6YW27YRdwVaElzFCpxYaS+kmygbjLBs2FFFE+uGSTR9JCoNCiZ1k6C+F+XOr/QPrJrzY2ekOHO8VAdD/feDcDQdz95hzBjF0JBcY5jfsOVn0M08d4je6fw+MeqhHCXVJRK4uQnb7/qu6D0ZtfF08= Stephen@localhost.localdomain"

litp create -t vm-ssh-key -p /software/services/vmservice6/vm_ssh_keys/4096key -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+9I8= Stephen@localhost.localdomain"


###################################
## SETUP DHCP FOR THE VM CLUSTER # 
###################################

litp create -t dhcp-service -p /software/services/dhcp -o service_name="dhcp" ntpservers="10.44.86.30","atsfsx82-data1.ammeonvpn.com","10.44.86.72","helios.ammeonvpn.com" nameservers=10.44.86.4 domainsearch=ammeonvpn.com,litp.com,libvirt.com

litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm1 -o network_name="net1vm"
litp create -t dhcp-range -p /software/services/dhcp/subnets/vm1/ranges/r1 -o start="10.46.83.100" end="10.46.83.120"

litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm2 -o network_name="net2vm"
litp create -t dhcp-range -p /software/services/dhcp/subnets/vm2/ranges/r1 -o start="10.46.80.90" end="10.46.80.100"
litp create -t dhcp-range -p /software/services/dhcp/subnets/vm2/ranges/r2 -o start="10.46.80.102" end="10.46.80.112"
litp create -t dhcp-range -p /software/services/dhcp/subnets/vm2/ranges/r3 -o start="10.46.80.115" end="10.46.80.125"

litp inherit -p /deployments/d1/clusters/c2/nodes/n3/services/dhcp -s /software/services/dhcp -o primary="false"
litp inherit -p /deployments/d1/clusters/c2/nodes/n4/services/dhcp -s /software/services/dhcp -o primary="true"

litp create_plan
