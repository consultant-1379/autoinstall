#!/bin/bash
#
# Sample LITP multi-blade deployment (SAN version)
#
# Usage:
#   ST_Deployment_11.sh <CLUSTER_SPEC_FILE>
#

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

litp update -p /ms/ -o hostname="${ms_host}"

# litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /software/profiles/os_prof1 -t os-profile -o name=sample_profile path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=vcs low_prio_net=mgmt llt_nets=heartbeat1,heartbeat2 cluster_id="${vcs_cluster_id}"  app_agent_num_threads=5
litp create -p /ms/services/cobbler -t cobbler-service 
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# Create storage volume group 1
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile #-o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd0 -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/pd2 -t physical-device -o device_name=hd2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
for (( i=0; i<2; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/VG1_FS$i -t file-system -o type=ext4 mount_point=/mp_VG1_FS$i size=200M snap_size=$((100-($i * 10))) backup_snap_size=$((100-($i * 5)))
done

# Create storage volume group 2
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2 -t volume-group -o volume_group_name=vg_secondDisk
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/pd1 -t physical-device -o device_name=hd1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/physical_devices/pd3 -t physical-device -o device_name=hd3
for (( i=0; i<3; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg2/file_systems/VG2FS$i -t file-system -o type=ext4 mount_point=/mp_VG2_FS$i size=500M snap_size=$((100-($i * 10))) backup_snap_size=$((100-($i * 5)))
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


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=28G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=10M bootable=false uuid="${node_disk2_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3 size=10M bootable=false uuid="${node_disk3_uuid[$i]}"
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


litp create -t eth -p /ms/network_interfaces/if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" network_name=mgmt ipv6address="${ms_ipv6_00}"
litp create -t eth -p /ms/network_interfaces/if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" ipaddress="${ms_ip_ext}" network_name=data ipv6address="${ms_ipv6_01}"
litp update -p /ms -o hostname="${ms_host}"

# 5 MS routes

litp inherit -p /ms/system -s /infrastructure/systems/sys1
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway}"
# litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"

# Create Nics

litp create -p /deployments/d1/clusters/c1/nodes/n1 -t node -o hostname="${node_hostname[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[0]}" ipaddress="${node_ip[0]}" network_name=mgmt ipv6address="${ipv6_00[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[0]}" network_name=data1 ipv6address="${ipv6_01[0]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=xxx1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=xxx2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[0]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if5 -o device_name=eth5 macaddress="${node_eth5_mac[0]}" network_name=heartbeat2
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[0]}" network_name=traffic1 ipaddress="${traf1_ip[0]}"


litp inherit -p /deployments/d1/clusters/c1/nodes/n1/system -s /infrastructure/systems/sys2
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${ms_gateway}"

litp create -p /deployments/d1/clusters/c1/nodes/n2 -t node -o hostname="${node_hostname[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if0 -o device_name=eth0 macaddress="${node_eth0_mac[1]}" ipaddress="${node_ip[1]}" network_name=mgmt ipv6address="${ipv6_00[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if1 -o device_name=eth1 macaddress="${node_eth1_mac[1]}" network_name=data1 ipv6address="${ipv6_01[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if2 -o device_name=eth2 macaddress="${node_eth2_mac[1]}" network_name=heartbeat1
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if3 -o device_name=eth3 macaddress="${node_eth3_mac[1]}" network_name=traffic1 ipaddress="${traf1_ip[1]}"
litp create -t eth -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/if4 -o device_name=eth4 macaddress="${node_eth4_mac[1]}" network_name=heartbeat2


litp inherit -p /deployments/d1/clusters/c1/nodes/n2/system -s /infrastructure/systems/sys3
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/os -s /software/profiles/os_prof1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/storage_profile -s /infrastructure/storage/storage_profiles/profile_1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route1 -s /infrastructure/networking/routes/route1
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${ms_gateway}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${ms_gateway}"

# Extra routes

litp create -p /infrastructure/networking/routes/traffic1_gw -t route -o subnet=10.19.72.0/24 gateway="${traf1_ip[0]}"
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw


# Create Vlan for MS and Nodes

# litp create -t network -p /infrastructure/networking/networks/network_898 -o name='test1_898' subnet='10.44.235.0/24'
# litp create -t vlan -p /ms/network_interfaces/vlan_898 -o device_name='eth1.898' network_name='test1_898' ipaddress='10.44.235.220'

# litp create -p /deployments/d1/clusters/c1/nodes/n1/network_interfaces/e1_898 -t vlan  -o device_name='eth1.898' network_name='test1_898' ipaddress='10.44.235.221'
# litp create -p /deployments/d1/clusters/c1/nodes/n2/network_interfaces/e1_898 -t vlan  -o device_name='eth1.898' network_name='test1_898' ipaddress='10.44.235.222'

# litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" network_name=traffic3 ipaddress="${traf1_ip[$i]}"
# litp create -t eth -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if7 -o device_name=eth7 macaddress="${node_eth5_mac[$i]}" network_name=traffic4 ipaddress="${traf2_ip[$i]}"



# Nas hfs exp
# litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex1 -o name="ex1" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs1" export_options="secure,ro,no_root_squash"
# litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex2 -o name="ex2" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs2" export_options="secure,ro,no_root_squash"
# litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex3 -o name="ex3" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs3" export_options="secure,ro,no_root_squash"
# litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex4 -o name="ex4" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs4" export_options="secure,ro,no_root_squash"
# litp create -t nfs-export -p /infrastructure/storage/storage_providers/nfs_service/exports/ex5 -o name="ex5" allowed_clients="${node_ip[0]},${node_ip[1]}" prefix="${sfs_prefix}" file_system="fs5" export_options="secure,ro,no_root_squash"

# litp create -t nfs-virtual-server -p /infrastructure/storage/storage_providers/nfs_service/ip_addresses/vip -o name="vip" address="${sfs_vip}"

# Firewall
# MS
litp create -t firewall-node-config -p /ms/configs/fw_config
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
 litp create -p /ms/configs/fw_config/rules/fw_icmpv6 -t firewall-rule -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
 litp create -p /ms/configs/fw_config/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

# CLUSTER
litp create -t firewall-cluster-config -p /deployments/d1/clusters/c1/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -t firewall-rule -p /deployments/d1/clusters/c1/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables


# add 1 FS

litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" 
litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs_vip}"

litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/sfsmount1" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2 -o export_path="${sfs_prefix}-fs2" provider="virtserv1" mount_point="/sfsmount2" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount3 -o export_path="${sfs_prefix}-fs3" provider="virtserv1" mount_point="/sfsmount3" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount4 -o export_path="${sfs_prefix}-fs4" provider="virtserv1" mount_point="/sfsmount4" mount_options="soft,intr" network_name="mgmt"
litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount5 -o export_path="${sfs_prefix}-fs5" provider="virtserv1" mount_point="/sfsmount5" mount_options="soft,intr" network_name="mgmt"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount2
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs3 -s /infrastructure/storage/nfs_mounts/mount3
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs4 -s /infrastructure/storage/nfs_mounts/mount4
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs5 -s /infrastructure/storage/nfs_mounts/mount5
done


# Non SFS (commented out as can't ping nfs_management_ip)
# litp create -t nfs-service -p /infrastructure/storage/storage_providers/nas_service_sp1 -o name="nas1" ipv4address="${nfs_management_ip}"
# litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nfs_prefix}/dir_share_140_C" provider="nas1" mount_point="/cluster_ro" mount_options="soft,intr" network_name="mgmt"
# litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nfs_prefix}/dir_share_140_A" provider="nas1" mount_point="/cluster_rw" mount_options="soft,intr" network_name="mgmt"

# for (( i=0; i<${#node_sysname[@]}; i++ )); do
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
# done


# Add sysparams 
# Sysparams
litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n1/configs/sysctl
litp create -t sysparam-node-config -p /deployments/d1/clusters/c1/nodes/n2/configs/sysctl

for (( i=0; i<${#node_sysname[@]}; i++ )); do
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_custom -o key="fs.file-max" value="26289446"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_max" value="5242880"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.wmem_default" value="655360"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_max" value="655360"
  litp create -t sysparam -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="kernel.core_pattern" value="/tmp/core.%e.pid%p.usr%u.sig%s.tim%t" 
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

done

litp create -t sysparam-node-config -p /ms/configs/sysctl
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_custom -o key="fs.file-max" value="26289448"
litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="kernel.core_pattern" value="/tmp/core.%e.pid%p.usr%u.sig%s.tim%t"

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

# Service Groups
# 2 F/O SGs - 1st SG #VIP=#AC 2nd SG  #VIP=2x#AC
# 1 PL  SGs - 

SG_pkg[x]="cups";    SG_rel[x]="67.el6"; SG_ver[x]="1.4.2";    SG_VIP_count[x]=3;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=30	status_timeout[x]=20	restart_limit[x]=2	startup_retry_limit[x]=1	node_list[x]="n2,n1" dependency_list[x]="SG_httpd" 	   x=$[$x+1]
SG_pkg[x]="luci";    SG_rel[x]="63.el6";     SG_ver[x]="0.26.0";   SG_VIP_count[x]=4;      SG_active[x]=1; SG_standby[x]=1 status_interval[x]=10	status_timeout[x]=10	restart_limit[x]=0	startup_retry_limit[x]=0	node_list[x]="n1,n2" dependency_list[x]="SG_cups"  	   x=$[$x+1]
SG_pkg[x]="httpd";   SG_rel[x]="39.el6";   SG_ver[x]="2.2.15";   SG_VIP_count[x]=$[5*2]; SG_active[x]=2; SG_standby[x]=0 status_interval[x]=20	status_timeout[x]=60	restart_limit[x]=10	startup_retry_limit[x]=10 	node_list[x]="n1,n2"					   x=$[$x+1]

vip_count=1
for (( x=0; x<${#SG_pkg[@]}; x++ )); do
litp create -t package               -p /software/items/"${SG_pkg[$x]}" -o name="${SG_pkg[$x]}" version="${SG_ver[$x]}" release="${SG_rel[$x]}"
litp create -t vcs-clustered-service -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}" -o active="${SG_active[$x]}" standby="${SG_standby[$x]}" name=vcs$(($x+1)) online_timeout=45 offline_timeout=45 node_list='n1,n2'
#litp create -t lsb-runtime           -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}" status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}" #cleanup_command=/opt/ericsson/cleanup_"${SG_pkg[$x]}".sh
#litp create -t service           -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}" status_interval="${status_interval[$x]}" status_timeout="${status_timeout[$x]}" restart_limit="${restart_limit[$x]}" startup_retry_limit="${startup_retry_limit[$x]}" #cleanup_command=/opt/ericsson/cleanup_"${SG_pkg[$x]}".sh
litp create -t service           -p /software/services/"${SG_pkg[$x]}" -o service_name="${SG_pkg[$x]}"
litp inherit                     -p /software/services/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"
litp inherit                     -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/applications/"${SG_pkg[$x]}" -s /software/services/"${SG_pkg[$x]}"
#litp inherit                    -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${SG_pkg[$x]}"

       for (( i=0; i<${SG_VIP_count[x]}; i++ )); do
#               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
#               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t1_ip6${i} -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip${i} -o ipaddress="${traf1_vip[$vip_count]}" network_name=traffic1
               litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/ipaddresses/t1_ip6${i} -o ipaddress="${traf1_vip_ipv6[$vip_count]}" network_name=traffic1
#                 litp create -t vip   -p /deployments/d1/clusters/c1/services/SG_"${SG_pkg[$x]}"/runtimes/"${SG_pkg[$x]}"/ipaddresses/t2_ip${i} -o ipaddress="${traf2_vip[$vip_count]}" network_name=traffic2
                vip_count=($vip_count+1)
        done
done

# Add repo

litp create -t yum-repository -p /software/items/yum_osHA_repo -o name=osHA base_url=http://ms1dot140/6/os/x86_64/HighAvailability
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n1/items/yum_osHA_repo
litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/c1/nodes/n2/items/yum_osHA_repo

# Add Packages 
litp create -t package -p /software/items/openjdk     -o name=java-1.7.0-openjdk
litp create -t package -p /software/items/cups-libs   -o name=cups-libs   release=67.el6 version=1.4.2 epoch=1 
litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6
litp inherit -p /ms/items/java -s /software/items/openjdk
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/cups-libs -s /software/items/cups-libs
done;

litp update -p /software/items/httpd -o epoch=0
litp update -p /software/items/luci -o epoch=0
litp update -p /software/items/cups -o epoch=1

# IPV6 routes
litp create -t route6 -p /infrastructure/networking/routes/route6_default -o subnet=::/0 gateway=${ipv6_836_gateway}

litp inherit -p /ms/routes/route6_default -s /infrastructure/networking/routes/route6_default
litp inherit -p /deployments/d1/clusters/c1/nodes/n1/routes/route6_default -s /infrastructure/networking/routes/route6_default
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/routes/route6_default -s /infrastructure/networking/routes/route6_default

litp create_plan

