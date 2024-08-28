#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_12.sh <CLUSTER_SPEC_FILE>
##

litp update -p /litp/logging -o force_debug=true

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=vcs low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"
#litp create -t clustered-service -p /deployments/d1/clusters/c1/services/PMmed -o active=1 standby=1 name=PMmed
litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# Create storage volume group 1
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile #-o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
for (( i=0; i<2; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/VG1_FS$i -t file-system -o type=ext4 mount_point=/mp_VG1_FS$i size=200M snap_size=$((100-($i * 10)))
done

# Create storage volume group 2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_secondDisk
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/internal -t physical-device -o device_name=hd1
for (( i=0; i<3; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/VG2FS$i -t file-system -o type=ext4 mount_point=/mp_VG2_FS$i size=500M snap_size=$((100-($i * 10)))
done
# done (VG1 and VG2)

### NTP ###
litp create -t ntp-service -p /software/items/ntp1 #-o name=ntp1


### Cluster Level Aliases ####
# Alias
litp create -t alias-cluster-config -p /deployments/d1/clusters/c1/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/c1/configs/alias_config/aliases/sfs_alias -o alias_names="sfsAlias","nasAlias" address="${sfs_management_ip}"

# Finished Creating Cluster Level Aliases

### MS Level Aliases ###
litp create -t alias-node-config -p /ms/configs/alias_config

for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
done

# done with NTP +3


# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name="master" password="master" service_type="SFS"
# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nfs_service -o service_name="sfs1" management_ip="${sfs_management_ip}" user_name='support' password_key='key-for-sfs' service_type="SFS"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -t route   -p /infrastructure/networking/routes/route1 -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"
litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${nodes_subnet}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data -o name=data subnet="${nodes_subnet_ext}" 
litp create -t network -p /infrastructure/networking/networks/data1 -o name=data1
litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2
litp create -t network -p /infrastructure/networking/networks/traffic1 -o name=traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/traffic2 -o name=traffic2 subnet="${traf2_subnet}"
litp create -t network -p /infrastructure/networking/networks/xxx1 -o name=xxx1
litp create -t network -p /infrastructure/networking/networks/xxx2 -o name=xxx2
litp create -t network -p /infrastructure/networking/networks/bare_nic -o name=bare_nic
litp create -t network -p /infrastructure/networking/networks/vlan1_node2 -o name=vlan1_node2 subnet="${nodes_subnet_ext}"
litp create -t network -p /infrastructure/networking/networks/subnet_834 -o name=netwk834
litp create -t network -p /infrastructure/networking/networks/subnet_835 -o name=netwk835
litp create -t network -p /infrastructure/networking/networks/subnet_836 -o name=netwk836 
litp create -t network -p /infrastructure/networking/networks/subnet_837 -o name=netwk837 


# MS NICs, bonds and Vlans

litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
litp create -t eth -p /ms/network_interfaces/if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond0
litp create -t bond -p /ms/network_interfaces/b0 -o device_name='bond0' mode=1 miimon=100 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt
# litp create -t vlan -p /ms/network_interfaces/bond0_835 -o device_name='bond0.835' ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

# litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt ipv6address="${ms_ipv6_00}"
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip_ext}" network_name=data ipv6address="${ms_ipv6_01}"
litp create -t eth  -p /ms/network_interfaces/if2 -o device_name=eth2 macaddress="${ms_eth2_mac}"
litp create -t vlan -p /ms/network_interfaces/vlan834 -o device_name=eth2.834                     network_name=netwk834 ipv6address="${ms_ipv6_02}"
# litp create -t vlan -p /ms/network_interfaces/vlan835 -o device_name=eth2.835                     network_name=netwk835 ipv6address="${ms_ipv6_03}"
litp create -t vlan -p /ms/network_interfaces/vlan836 -o device_name=eth2.836                     network_name=netwk836 ipv6address="${ms_ipv6_04}"
litp create -t vlan -p /ms/network_interfaces/vlan837 -o device_name=eth2.837                     network_name=netwk837 ipv6address="${ms_ipv6_05}"



# 5 MS routes

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 	-o subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1	-o subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 	-o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 	-o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"

litp update -p /ms -o hostname="${ms_host}"

# Create Nics

litp create -p /deployments/d1/clusters/c1/nodes/n1 -t node -o hostname=node1dot90
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 	     -o device_name=eth0 macaddress="${node_eth0_mac[0]}" network_name=data1 ipv6address="${ipv6_00[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1            -o device_name=eth1 macaddress="${node_eth1_mac[0]}" master=bond0
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if7 	     -o device_name=eth7 macaddress="${node_eth7_mac[0]}" master=bond0
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b0 	     -o device_name='bond0' mode=1 miimon=100 ipv6address="${ipv6_01[0]}" ipaddress="${node_ip[0]}" network_name=mgmt

# litp create -t bond -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/b1 	     -o device_name='bond1' mode=1 miimon=100 ipv6address="${ipv6_19[0]}" network_name=xxx1
# litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 	     -o device_name=eth2 macaddress="${node_eth2_mac[0]}" master=bond1
# litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3            -o device_name=eth3 macaddress="${node_eth3_mac[0]}" master=bond1

litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 	     -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=xxx1 ipv6address="${ipv6_19[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 	     -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=xxx2 ipv6address="${ipv6_12[0]}"

litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan834       -o device_name=eth3.834  network_name=netwk834 ipv6address="${ipv6_11[0]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan835       -o device_name=eth3.835  network_name=netwk835 ipv6address="${ipv6_13[0]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan836       -o device_name=eth3.836  network_name=netwk836 ipv6address="${ipv6_14[0]}" 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/vlan837       -o device_name=eth3.837  network_name=netwk837 ipv6address="${ipv6_15[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 	     -o device_name=eth4 macaddress="${node_eth4_mac[0]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 	     -o device_name=eth5 macaddress="${node_eth5_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if6 	     -o device_name=eth6 macaddress="${node_eth6_mac[0]}" network_name=traffic1 ipaddress="${traf1_ip[0]}" ipv6address="${ipv6_16[0]}"

# Add routes for node1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/system -s /infrastructure/systems/sys2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route2 -s /infrastructure/networking/routes/route1 	-o subnet="${route2_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route3 -s /infrastructure/networking/routes/route1 	-o subnet="${route3_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route4 -s /infrastructure/networking/routes/route1 	-o subnet="${route4_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route5 -s /infrastructure/networking/routes/route1 	-o subnet="${route_subnet_801}" gateway="${ms_gateway}"

litp create -p /deployments/d1/clusters/c1/nodes/n2 -t node -o hostname=node2dot90
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 	-o device_name=eth0 macaddress="${node_eth0_mac[1]}" master=bond0
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if6 	-o device_name=eth6 macaddress="${node_eth6_mac[1]}" master=bond0
litp create -t bond -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/b0 	-o device_name='bond0' mode=1 miimon=100 ipv6address="${ipv6_01[0]}" ipaddress="${node_ip[1]}" network_name=mgmt
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1 	-o device_name=eth1 macaddress="${node_eth1_mac[1]}" network_name=data1 ipv6address="${ipv6_01[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 	-o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 	-o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=traffic1 ipaddress="${traf1_ip[1]}" ipv6address="${ipv6_15[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 	-o device_name=eth4 macaddress="${node_eth4_mac[1]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if5 	-o device_name=eth5 macaddress="${node_eth5_mac[1]}" network_name=bare_nic
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if7 	-o device_name=eth7 macaddress="${node_eth7_mac[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan834       -o device_name=eth7.834  network_name=netwk834 ipv6address="${ipv6_16[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan835       -o device_name=eth7.835  network_name=netwk835 ipv6address="${ipv6_11[1]}"
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan836       -o device_name=eth7.836  network_name=netwk836 ipv6address="${ipv6_12[1]}" 
litp create -t vlan -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/vlan837       -o device_name=eth7.837  network_name=netwk837 ipv6address="${ipv6_13[1]}"


# Adding routes

litp inherit -p /deployments/d1/clusters/c1/nodes/n2/system -s /infrastructure/systems/sys3
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${ms_gateway}"

# Network hosts

litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_10 -o network_name=traffic1 ip="${ipv6_16[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_ipv6_20 -o network_name=traffic1 ip="${ipv6_17[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/c1/network_hosts/traffic1_bare_nic -o network_name=bare_nic ip="${ipv6_18[0]}"


# Firewall

# CLUSTER
litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o 'name=100 icmp' proto=icmp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmpv6 -o 'name=101 icmpv6' proto=ipv6-icmp provider=ip6tables


# NODE
for (( i=0; i<${#node_sysname[@]}; i++ )); do

  litp create -t firewall-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config
  litp create -t firewall-rule -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp

done

# add 5 FS

litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1"
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/sfsmount1" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2 -o export_path="${sfs_prefix}-fs2" provider="virtserv1" mount_point="/sfsmount2" mount_options="soft,intr" network_name="mgmt"
# till I add them to .231 litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount3 -o export_path="${sfs_prefix}-fs3" provider="virtserv1" mount_point="/sfsmount3" mount_options="soft,intr" network_name="mgmt"
# till I add them to .231 litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount4 -o export_path="${sfs_prefix}-fs4" provider="virtserv1" mount_point="/sfsmount4" mount_options="soft,intr" network_name="mgmt"
# till I add them to .231 litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount5 -o export_path="${sfs_prefix}-fs5" provider="virtserv1" mount_point="/sfsmount5" mount_options="soft,intr" network_name="mgmt"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountArad -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/ms_share_sfs" mount_options="soft,intr" network_name="mgmt"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount2
# till I add them to .231     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mount3
# till I add them to .231     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mount4
# till I add them to .231     litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs5 -s /infrastructure/storage/nfs_mounts/mount5
done

# Non SFS

litp create -t nfs-service -p /infrastructure/storage/storage_providers/nas_service_sp1 -o name="nas1" ipv4address="${nfs_management_ip}"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nfs_prefix}/dir_share_90_C" provider="nas1" mount_point="/cluster_ro" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nfs_prefix}/dir_share_90_A" provider="nas1" mount_point="/cluster_rw" mount_options="soft,intr" network_name="mgmt"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountCaransebes -o export_path="${nfs_prefix}/dir_share_90_C" provider="nas1" mount_point="/ms_share_nfs" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mountDrobeta -o export_path="${nfs_prefix}/dir_share_90_B" provider="nas1" mount_point="/ms_share_nfs1" mount_options="soft,intr" network_name="mgmt"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
done

#MS
litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mountArad
litp inherit -p /ms/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mountCaransebes
litp inherit -p /ms/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mountDrobeta


#Sysparms 

litp create -t sysparam-node-config -p /ms/configs/mynodesysctl 
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_M1 -o key=net.ipv4.udp_mem value="24794401 33059201 49588801"
litp create -t sysparam -p /ms/configs/mynodesysctl/params/sysctl_M2 -o key=net.ipv6.route.mtu_expires value=599


litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl
litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl/params/sysctl_mn1_02 -o  key="net.core.netdev_max_backlog" value="30000"
litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n1/configs/mynodesysctl/params/sysctl_mn1_03 -o  key="net.ipv4.tcp_mem" value="8388608 8388608 8388608"

litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl
litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl/params/sysctl_mn2_02 -o  key="net.core.netdev_max_backlog" value="30000"
litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n2/configs/mynodesysctl/params/sysctl_mn2_03 -o  key="net.ipv4.tcp_mem" value="8388608 8388608 8388608"


# Service Groups
# 2 F/O SGs - 1st SG #VIP=#AC 2nd SG  #VIP=2x#AC
# 1 PL  SGs - 

x=0
SG_pkg[x]="cups";    SG_rel[x]="50.el6_4.5"; SG_ver[x]="1.4.2";    SG_VIP_count[x]=3;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=30	status_timeout[x]=20	restart_limit[x]=2	startup_retry_limit[x]=1	x=$[$x+1]
SG_pkg[x]="luci";    SG_rel[x]="37.el6";     SG_ver[x]="0.26.0";   SG_VIP_count[x]=4;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=10	status_timeout[x]=10	restart_limit[x]=0	startup_retry_limit[x]=0	x=$[$x+1]
SG_pkg[x]="httpd";   SG_rel[x]="29.el6_4";     SG_ver[x]="2.2.15";   SG_VIP_count[x]=$[5*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20	status_timeout[x]=60	restart_limit[x]=10	startup_retry_limit[x]=10	x=$[$x+1]
# SG_pkg[x]="ricci"; SG_rel[x]="63.el6";     SG_ver[x]="0.16.2";   SG_rel[x]="63.el6"; 	SG_ver[x]="0.16.2";     SG_VIP_count[x]=$[2*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=1000	status_timeout[x]=1000	restart_limit[x]=1000startup_retry_limit[x]=1000	x=$[$x+1]

vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" repository=OS version="${SG_ver[$x]}" release="${SG_rel[$x]}"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs$(($x+1)) online_timeout=45 node_list='n1,n2'
#litp create -t lsb-runtime           -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}" status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}" #cleanup_command=/opt/ericsson/cleanup_"${SG_pkg[$x]}".sh
#litp create -t service           -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}" status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}" #cleanup_command=/opt/ericsson/cleanup_"${SG_pkg[$x]}".sh
litp create -t service           -p /software/services/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}"
litp inherit                     -p /software/services/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
litp inherit                     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/applications/"${SG_pkg[$x]}" -s /software/services/"${SG_pkg[$x]}"
#litp inherit                    -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"

       for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
#               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
#               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t1_ip6${i} -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
#               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip6${i} -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
#                 litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
                vip_count=($vip_count+1)
        done
done

litp create_plan
