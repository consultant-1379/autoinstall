#!/bin/bash
#
# Sample LITP multi-blade deployment ('local disk' version)
#
# Usage:
#   ST_Deployment_8.sh <CLUSTER_SPEC_FILE>
#
# VCS Cluster (sfha)
#
# 5 NICS on Peer Nodes
# 2 NICS on MS
# 2 ntp servers
# 1 Failover VCS Service Group
# 2 Parallel VCS Service Groups
# Firewall enabled at MS Level


if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x
litp update -p /litp/logging -o force_debug=true
litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support "${sfs_password}"

#litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
#litp create -t yum-repository -p /software/items/yum_osHA_repo -o name="osHA" base_url="http://ms1dot51/6/os/x86_64/HighAvailability"
#litp create -p /deployments/d1 -t deployment

### 1 VCS Cluster - VCS Type ###
litp create -t vcs-cluster -p /deployments/d1/clusters/tizon -o cluster_type=vcs low_prio_net=mgmt llt_nets=hb1,hb2 cluster_id="${vcs_cluster_id}"

#litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_tizon -t storage-profile -o volume_driver=lvm #-o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/file_systems/file1 -t file-system -o type=ext4 mount_point=/file1 size=1G
litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/file_systems/file2 -t file-system -o type=ext4 mount_point=/file2 size=1G
litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
#litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/physical_devices/pd0 -t physical-device -o device_name=hd1
#litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/physical_devices/pd1 -t physical-device -o device_name=hd3

for (( i=0; i<2; i++ )); do
        litp create -p /infrastructure/storage/storage_profiles/profile_tizon/volume_groups/vg1/file_systems/VG1_FS$i -t file-system -o type=ext4 mount_point=/mp_VG1_FS$i size=200M snap_size=$((100-($i * 10)))
done

#litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

# STORAGE
# LVM Storage Profile
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+6)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+6))/disks/disk0 -t disk -o name=hd0 size=27G bootable=true uuid="${node_disk_uuid[$i]}"
#    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=2G bootable=false uuid="${vxvm_disk_uuid_00[$i]}"
#    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=20G bootable=false uuid="${vxvm_disk_uuid_01[$i]}"
#    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3 size=3G bootable=false uuid="${vxvm_disk_uuid_02[$i]}"
#    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk4 -t disk -o name=hd4 size=3G bootable=false uuid="${vxvm_disk_uuid_03[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+6))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

# VXVM Storage Profile
#litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver=vxvm
#litp create -t volume-group -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1 -o volume_group_name=vxvg1
#litp create -t file-system -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/file_systems/fs1 -o type=vxfs size=1G mount_point=/vxvm_vol1 snap_size=100
#litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/physical_devices/pd0 -o device_name=hd4
##litp create -t physical-device -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vxvg1/physical_devices/pd1 -o device_name=hd2

# VCS Cluster inherits the VXVM Profile 
#litp inherit -p /deployments/d1/clusters/tizon/storage_profile/sp2 -s /infrastructure/storage/storage_profiles/profile_2

# IPv4 Routes
#litp create -p /infrastructure/networking/routes/tiz_route1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}" #name=default 
#litp create -p /infrastructure/networking/routes/tiz_route2 -t route -o subnet="${route2_subnet}" gateway="${nodes_gateway}" 
#litp create -p /infrastructure/networking/routes/tiz_route3 -t route -o subnet="${route3_subnet}" gateway="${nodes_gateway}" 
#litp create -p /infrastructure/networking/routes/tiz_route4 -t route -o subnet="${route4_subnet}" gateway="${nodes_gateway}"
#litp create -p /infrastructure/networking/routes/tiz_route5 -t route -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}"
#litp create -p /infrastructure/networking/routes/tiz_traffic1_gw -t route -o subnet="${traf1gw_subnet}" gateway="${traf1_ip[1]}"
#litp create -p /infrastructure/networking/routes/tiz_traffic2_gw -t route -o subnet="${traf2gw_subnet}" gateway="${traf2_ip[1]}"

# IPv6 Routes
#litp create -t route6 -p /infrastructure/networking/routes/default_tiz_ipv6 -o subnet=::/0 gateway="${ipv6_835_gateway}"
##litp create -t route6 -p /infrastructure/networking/routes/ipv6_r1 -o subnet="${ipv6_836_network}" gateway="${ipv6_834_gateway}"
#litp create -t route6 -p /infrastructure/networking/routes/tiz_ipv6_r2 -o subnet="${ipv6_dummy_network}" gateway="${ipv6_traf2_gateway}"

#litp create -t network -p /infrastructure/networking/networks/mgmt -o name=mgmt subnet="${netwrk898}" litp_management=true
litp create -t network -p /infrastructure/networking/networks/data1 -o name=data1 subnet="${netwrk836}"
#litp create -t network -p /infrastructure/networking/networks/netwrk898 -o name=netwrk898 subnet="${netwrk898}"
#litp create -t network -p /infrastructure/networking/networks/netwrk834 -o name=netwrk834 subnet="${netwrk834}"
#litp create -t network -p /infrastructure/networking/networks/netwrk835 -o name=netwrk835 subnet="${netwrk835}"
#litp create -t network -p /infrastructure/networking/networks/netwrk836 -o name=netwrk836 subnet="${netwrk836}"
#litp create -t network -p /infrastructure/networking/networks/netwrk837 -o name=netwrk837 subnet="${netwrk837}"

#litp create -t network -p /infrastructure/networking/networks/heartbeat1 -o name=heartbeat1
#litp create -t network -p /infrastructure/networking/networks/heartbeat2 -o name=heartbeat2


# Cluster Level Aliases
litp create -t alias-cluster-config -p /deployments/d1/clusters/tizon/configs/alias_config
litp create -t alias -p /deployments/d1/clusters/tizon/configs/alias_config/aliases/master_cluster_alias -o alias_names="master-c-alias" address="10.10.10.100"
litp create -t alias -p /deployments/d1/clusters/tizon/configs/alias_config/aliases/ldap_cluster_alias -o alias_names="ldap-c-alias" address="10.10.10.240"
litp create -t alias -p /deployments/d1/clusters/tizon/configs/alias_config/aliases/mysql_queue_cluster_alias -o alias_names="mysql-c-alias,queue-c-alias" address="10.10.10.222"
# Finished Creating Cluster Level Aliases

# MS Level Aliases
#litp create -t alias-node-config -p /ms/configs/alias_config
#for (( i=0; i<${#ntp_ip[@]}; i++ )); do
#    litp create -t alias -p /ms/configs/alias_config/aliases/ntp_alias_$(($i+1)) -o alias_names=ntp-alias-$(($i+1)) address="${ntp_ip[i+1]}"
#done

# VCS Service Groups
#Create a SW Package
litp create -t package -p /software/items/ricci -o name=ricci release=75.el6 version=0.16.2 epoch=0
#litp create -t package -p /software/items/httpd -o name=httpd release=39.el6 version=2.2.15 epoch=0
#litp create -t package -p /software/items/luci -o name=luci release=63.el6 version=0.26.0 epoch=0
#litp create -t package -p /software/items/dovecot -o name=dovecot release=7.el6_5.1 version=2.0.9 epoch=1
#litp create -t package -p /software/items/cups -o name=cups release=67.el6 version=1.4.2 epoch=1

# Pin dependent packages to support version pinning of LSB Packages above
#litp create -t package -p /software/items/httpd-tools -o name=httpd-tools version=2.2.15 release=39.el6 epoch=0
litp create -t package -p /software/items/cups-libs -o name=cups-libs version=1.4.2 release=67.el6 epoch=1
#litp create -t package -p /software/items/openjdk     -o name=java-1.7.0-openjdk

#litp inherit -p /ms/items/java -s /software/items/openjdk

# Sentinel
#litp create -t package -p /software/items/sentinel -o name="EXTRlitpsentinellicensemanager_CXP9031488"
#litp inherit -p /ms/items/sentinel -s /software/items/sentinel
#litp create -t service -p /ms/services/sentinel -o service_name="sentinel"
#litp create -t service -p /software/services/sentinel -o service_name="sentinel"
#litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

# Create Failover VCS Service Group
litp create -t vcs-clustered-service -p /deployments/d1/clusters/tizon/services/apachecs -o active=1 standby=1 name=vcs1 online_timeout=45 node_list='tizon1,tizon2' dependency_list=cups,luci
litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/apachecs/ha_configs/conf1 -o status_interval=50 status_timeout=60 restart_limit=5 startup_retry_limit=2
litp create -t vcs-clustered-service -p /deployments/d1/clusters/tizon/services/ricci -o active=1 standby=1 name=vcs4 online_timeout=70 node_list='tizon2,tizon1'
litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/ricci/ha_configs/conf1 -o status_interval=60 status_timeout=60 restart_limit=5 startup_retry_limit=2

# Create Parallel VCS Service Groups
litp create -t vcs-clustered-service -p /deployments/d1/clusters/tizon/services/luci -o active=2 standby=0 name=vcs2 online_timeout=90 node_list='tizon1,tizon2' dependency_list=ricci
litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/luci/ha_configs/conf1 -o status_interval=50 status_timeout=60 restart_limit=5 startup_retry_limit=2

litp create -t vcs-clustered-service -p /deployments/d1/clusters/tizon/services/cups -o active=2 standby=0 name=vcs3 online_timeout=90 node_list='tizon1,tizon2'
litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/cups/ha_configs/conf1 -o status_interval=40 status_timeout=60 restart_limit=5 startup_retry_limit=2

# Create the LSB Service item type.
#litp create -t service -p /software/services/httpd -o service_name=httpd
#litp inherit -p /software/services/httpd/packages/pkg1 -s /software/items/httpd
litp inherit -p /deployments/d1/clusters/tizon/services/apachecs/applications/httpd -s /software/services/httpd
#litp create -t service -p /software/services/cups -o service_name=cups
#litp inherit -p /software/services/cups/packages/pkg1 -s /software/items/cups
litp inherit -p /deployments/d1/clusters/tizon/services/cups/applications/cups -s /software/services/cups
#litp create -t service -p /software/services/luci -o service_name=luci
#litp inherit -p /software/services/luci/packages/pkg1 -s /software/items/luci
litp inherit -p /deployments/d1/clusters/tizon/services/luci/applications/luci -s /software/services/luci
litp create -t service -p /software/services/ricci -o service_name=ricci
litp inherit -p /software/services/ricci/packages/pkg1 -s /software/items/ricci
litp inherit -p /deployments/d1/clusters/tizon/services/ricci/applications/ricci -s /software/services/ricci


# Create the networks
litp create -t network -p /infrastructure/networking/networks/tiz_traffic1 -o name=tiz_traffic1 subnet="${traf1_subnet}"
litp create -t network -p /infrastructure/networking/networks/tiz_traffic2 -o name=tiz_traffic2 subnet="${traf2_subnet}"

# Finished Creating VCS Cluster Service Groups
# 2 MS NIC
# MS - 4 eth - 2 bonds
#litp create -t eth -p /ms/network_interfaces/tiz_if0 -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bond0
#litp create -t eth -p /ms/network_interfaces/tiz_if1 -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bond0
#litp create -t eth -p /ms/network_interfaces/tiz_if2 -o device_name=eth2 macaddress="${ms_eth2_mac}" master=bond1
#litp create -t eth -p /ms/network_interfaces/tiz_if3 -o device_name=eth3 macaddress="${ms_eth3_mac}" master=bond1

#litp create -t bond -p /ms/network_interfaces/tiz_b0 -o device_name='bond0' ipaddress="${ms_ip_898_bond}" network_name=mgmt mode=1 miimon=100
#litp create -t bond -p /ms/network_interfaces/tiz_b1 -o device_name='bond1' ipaddress="${ms_ip_836_bond}" network_name=data mode=1 miimon=100
#litp create -t bond -p /ms/network_interfaces/tiz_b0 -o device_name='bond0' ipaddress="${ms_ip_898_bond}" ipv6address="${ms_ipv6_898_bond}" network_name=mgmt mode=1 miimon=100
#litp create -t bond -p /ms/network_interfaces/tiz_b1 -o device_name='bond1' ipaddress="${ms_ip_836_bond}" ipv6address="${ms_ipv6_836_bond}" network_name=data mode=1 miimon=100

#litp create -t vlan -p /ms/network_interfaces/bond0_834 -o device_name='bond0.834' ipaddress="${ms_ip_834}" ipv6address="${ms_ipv6_834}" network_name='netwrk834'
##litp create -t vlan -p /ms/network_interfaces/bond0_898 -o device_name='bond0.898' ipaddress="${ms_ip_898}" ipv6address="${ms_ipv6_898}" network_name='netwrk898'
#litp create -t vlan -p /ms/network_interfaces/bond1_835 -o device_name='bond1.835' ipaddress="${ms_ip_835}" ipv6address="${ms_ipv6_835}" network_name='netwrk835'
##litp create -t vlan -p /ms/network_interfaces/bond1_836 -o device_name='bond1.836' ipaddress="${ms_ip_836}" ipv6address="${ms_ipv6_836}" network_name='netwrk836'
#litp create -t vlan -p /ms/network_interfaces/bond1_837 -o device_name='bond1.837' ipaddress="${ms_ip_837}" ipv6address="${ms_ipv6_837}" network_name='netwrk837'



#litp update -p /ms -o hostname="$ms_host"
# 5 MS Routes
#litp inherit -p /ms/system -s /infrastructure/systems/sys1
#litp inherit -p /ms/routes/route1 -s /infrastructure/networking/routes/route1
##litp inherit -p /ms/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}" #name=route2 
##litp inherit -p /ms/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}" #name=route3 
##litp inherit -p /ms/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}" #name=route4 
#litp inherit -p /ms/routes/route5 -s /infrastructure/networking/routes/route1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}" #name=route5 
#litp inherit -p /ms/routes/default_ipv6 -s /infrastructure/networking/routes/default_ipv6
##litp inherit -p /ms/routes/ipv6_r1 -s /infrastructure/networking/routes/ipv6_r1

#SysCtl Parameters
# MS
#litp create -t sysparam-node-config -p /ms/configs/sysctl
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="100000000"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="100000000"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="640000"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="640000"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
#litp create -t sysparam -p /ms/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"

### NTP ###
#litp create -t ntp-service -p /software/items/ntp1 #-o name=ntp1
#litp inherit -p /ms/items/ntp -s /software/items/ntp1
#for (( i=0; i<${#ntp_ip[@]}; i++ )); do
#    litp create -t ntp-server -p /software/items/ntp1/servers/server"$i" -o server=ntp-alias-$(($i+1))
#done

# Create nodes
# 6 MNs NICs
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    # Creating Node Level Aliases
    litp create -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/alias_config -t alias-node-config 
    litp create -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/alias_config/aliases/master_node_alias -t alias -o alias_names="master-n-alias" address="10.10.10.10"
    # Finished Creating Node Level Aliases
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/system -s /infrastructure/systems/sys$(($i+6))
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/os -s /software/profiles/os_prof1

    litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/network_interfaces/tiz_if4 -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name=tiz_traffic1 ipaddress="${traf1_ip[$i]}" ipv6address="${ipv6_04[$i]}"
    litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/network_interfaces/tiz_if5 -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name=tiz_traffic2 ipaddress="${traf2_ip[$i]}" ipv6address="${ipv6_05[$i]}"

    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_tizon
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/route1 -s /infrastructure/networking/routes/r1
#    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/route2 -s /infrastructure/networking/routes/route1 -o subnet="${route2_subnet}" gateway="${nodes_gateway}" #name=route2 
#    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/route3 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${nodes_gateway}" #name=route3
#    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/route4 -s /infrastructure/networking/routes/route1 -o subnet="${route4_subnet}" gateway="${nodes_gateway}" #name=route4
    #litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/route5 -s /infrastructure/networking/routes/r1 -o subnet="${route_subnet_801}" gateway="${nodes_gateway_ext}" #name=route5
#  litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/route6 -s /infrastructure/networking/routes/route1 -o subnet="${route3_subnet}" gateway="${node_ip_898_bond[$i]}"
    #litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/traffic1_gw -s /infrastructure/networking/routes/traffic1_gw
    #litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
#    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/default_ipv6 -s /infrastructure/networking/routes/default_ipv6
#    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/ipv6_r1 -s /infrastructure/networking/routes/ipv6_r1
    #litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/routes/ipv6_r2 -s /infrastructure/networking/routes/ipv6_r2
    # Pin dependent packages to support version pinning of LSB Packages above
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/items/java        -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/items/httpd-tools -s /software/items/httpd-tools
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/items/cups-libs   -s /software/items/cups-libs

    litp update -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1)) -o node_id=$[$i+1]

    litp inherit -s /software/items/yum_osHA_repo -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/items/yum_osHA_repo

    #Sentinel
    litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/services/sentinel -s /software/services/sentinel

    # SysCtl Params
    litp create -t sysparam-node-config -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm1 -o key="net.core.rmem_default" value="100000000"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm2 -o key="net.core.rmem_max" value="100000000"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm3 -o key="net.core.wmem_default" value="640000"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm4 -o key="net.core.wmem_max" value="640000"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm5 -o key="vm.swappiness" value="10"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm6 -o key="kernel.core_pattern" value="/ericsson/tor/dumps/core.%e.pid%p.usr%u.sig%s.tim%t"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm7 -o key="vm.nr_hugepages" value="47104"
    litp create -t sysparam -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/sysctl/params/sysctl_enm8 -o key="vm.hugetlb_shm_group" value="205"

done

litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_if0 -o device_name=eth0 macaddress="${node_eth0_mac[0]}" master=bond0 
#litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_if6 -o device_name=eth6 macaddress="${node_eth6_mac[0]}" master=bond0 
litp create -t bond -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_b0 -o device_name='bond0' ipaddress="${node_ip_898_bond[0]}" network_name=mgmt mode=1 miimon=100
#litp create -t bond -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_b0 -o device_name='bond0' ipaddress="${node_ip_898_bond[0]}" ipv6address="${node_ipv6_898_bond[0]}" network_name=mgmt mode=1 miimon=100

#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond0_834  -o device_name='bond0.834' ipaddress="${node_ip_834[0]}" ipv6address="${node_ipv6_834[0]}" network_name='netwrk834'
##litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond0_898  -o device_name='bond0.898' ipaddress="${node_ip_898[0]}" ipv6address="${node_ipv6_898[0]}" network_name='netwrk898'

litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_if1 -o device_name=eth1 macaddress="${node_eth1_mac[0]}" master=bond1
litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_if7 -o device_name=eth7 macaddress="${node_eth7_mac[0]}" master=bond1 
litp create -t bond -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/b1 -o device_name='bond1' ipaddress="${node_ip_836_bond[0]}" network_name=data1 mode=1 miimon=100
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_835  -o device_name='bond1.835' ipaddress="${node_ip_835[0]}" ipv6address="${node_ipv6_835[0]}" network_name='netwrk835'
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_837  -o device_name='bond1.837' ipaddress="${node_ip_837[0]}" ipv6address="${node_ipv6_837[0]}" network_name='netwrk837'
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_836  -o device_name='bond1.836' ipaddress="${node_ip_836[0]}" ipv6address="${node_ipv6_836[0]}" network_name='netwrk836'


litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_if0 -o device_name=eth0 macaddress="${node_eth0_mac[1]}" master=bond0 
#litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_if2 -o device_name=eth2 macaddress="${node_eth2_mac[1]}" master=bond0 
litp create -t bond -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_b0 -o device_name='bond0' ipaddress="${node_ip_898_bond[1]}" network_name=mgmt mode=1 miimon=100
#litp create -t bond -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_b0 -o device_name='bond0' ipaddress="${node_ip_898_bond[1]}" ipv6address="${node_ipv6_898_bond[1]}" network_name=mgmt mode=1 miimon=100
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond0_834  -o device_name='bond0.834' ipaddress="${node_ip_834[1]}" ipv6address="${node_ipv6_834[1]}" network_name='netwrk834'
##litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond0_898  -o device_name='bond0.898' ipaddress="${node_ip_898[1]}" ipv6address="${node_ipv6_898[1]}" network_name='netwrk898'

litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_if1 -o device_name=eth1 macaddress="${node_eth1_mac[1]}" master=bond1 
litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_if3 -o device_name=eth3 macaddress="${node_eth3_mac[1]}" master=bond1 
litp create -t bond -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/b1 -o device_name='bond1' ipaddress="${node_ip_836_bond[1]}" network_name=data1 mode=1 miimon=100
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_835  -o device_name='bond1.835' ipaddress="${node_ip_835[1]}" ipv6address="${node_ipv6_835[1]}" network_name='netwrk835'
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_837  -o device_name='bond1.837' ipaddress="${node_ip_837[1]}" ipv6address="${node_ipv6_837[1]}" network_name='netwrk837'
##litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_836  -o device_name='bond1.836' ipaddress="${node_ip_836[1]}" ipv6address="${node_ipv6_836[1]}" network_name='netwrk836'



##### Firewalls #######

#cluster level

litp create -t firewall-cluster-config -p /deployments/d1/clusters/tizon/configs/fw_config
litp create -t firewall-rule -p /deployments/d1/clusters/tizon/configs/fw_config/rules/fw_vmhc -o 'name=300 vmhc' proto=tcp dport=12987 provider=iptables

# MS 
#litp create -t firewall-node-config -p /ms/configs/fw_config
#litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
#litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
#litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=53,111,2049,4001,67,68 proto=udp
#litp create -t firewall-rule -p /ms/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=53,111,2049,4001,647 proto=tcp

# NODE
for (( i=0; i<${#node_sysname[@]}; i++ )); do

  litp create -t firewall-node-config -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/fw_config
  litp create -t firewall-rule -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/fw_config/rules/fw_nfsudp -o 'name=011 nfsudp' dport=53,111,2049,4001,67,68 proto=udp
  litp create -t firewall-rule -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/fw_config/rules/fw_nfstcp -o 'name=001 nfstcp' dport=53,111,2049,4001,647 proto=tcp
  litp create -t firewall-rule -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/fw_config/rules/fw_icmp -o name="100 icmp" proto="icmp"
  litp create -t firewall-rule -p /deployments/d1/clusters/tizon/nodes/tizon$(($i+1))/configs/fw_config/rules/fw_icmpv6 -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables

done

# LLT Links
litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_if2 -o device_name=eth2 macaddress="${node_eth2_mac[0]}" network_name=hb1 #ipv6address="${ipv6_02[0]}"
litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_if6 -o device_name=eth6 macaddress="${node_eth6_mac[1]}" network_name=hb1 #ipv6address="${ipv6_06[1]}"
litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/tiz_if3 -o device_name=eth3 macaddress="${node_eth3_mac[0]}" network_name=hb2 #ipv6address="${ipv6_03[0]}"
litp create -t eth -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/tiz_if7 -o device_name=eth7 macaddress="${node_eth7_mac[1]}" network_name=hb2 #ipv6address="${ipv6_07[1]}"

# FO SG1 #VIPs = 5x #AC(1) .......5 IPv4 + 5 IPv6 VIPs per Traffic1 Network, 5 IPv4 VIPs per Traffic2 Network
for (( i=1; i<6; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/tizon/services/apachecs/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i))]}"  network_name=tiz_traffic1
 litp create -t vip -p /deployments/d1/clusters/tizon/services/apachecs/ipaddresses/ip$(($i+5)) -o ipaddress="${traf1_vip_ipv6[$(($i))]}"  network_name=tiz_traffic1
 litp create -t vip -p /deployments/d1/clusters/tizon/services/apachecs/ipaddresses/ip$(($i+10)) -o ipaddress="${traf2_vip[$(($i))]}" network_name=tiz_traffic2

done

# PAR SG3 #VIPs = 2x #AC(2) ..........4 IPv4 + 4 IPv6 VIPs per Traffic1 Network, 4 IPv4 VIPs per Traffic2 Network
for (( i=1; i<5; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/tizon/services/luci/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i+5))]}" network_name=tiz_traffic1
 litp create -t vip -p /deployments/d1/clusters/tizon/services/luci/ipaddresses/ip$(($i+4)) -o ipaddress="${traf1_vip_ipv6[$(($i+5))]}" network_name=tiz_traffic1
 litp create -t vip -p /deployments/d1/clusters/tizon/services/luci/ipaddresses/ip$(($i+8)) -o ipaddress="${traf2_vip[$(($i+5))]}" network_name=tiz_traffic2

done

# FO SG4 #VIPs = 5x #AC(1) .......5 IPv4 + 5 IPv6 VIPs per Traffic1 Network, 5 IPv4 VIPs per Traffic2 Network
for (( i=1; i<6; i++ )); do

 litp create -t vip -p /deployments/d1/clusters/tizon/services/ricci/ipaddresses/ip${i} -o ipaddress="${traf1_vip[$(($i+11))]}"  network_name=tiz_traffic1
 litp create -t vip -p /deployments/d1/clusters/tizon/services/ricci/ipaddresses/ip$(($i+5)) -o ipaddress="${traf1_vip_ipv6[$(($i+11))]}"  network_name=tiz_traffic1
 litp create -t vip -p /deployments/d1/clusters/tizon/services/ricci/ipaddresses/ip$(($i+10)) -o ipaddress="${traf2_vip[$(($i+11))]}" network_name=tiz_traffic2

done

# PAR SG2 #VIPs = NONE

# Add FO SG Filesystem
# litp inherit -p /deployments/d1/clusters/tizon/services/apachecs/filesystems/fs1 -s /deployments/d1/clusters/tizon/storage_profile/sp2/volume_groups/vxvg1/file_systems/fs1

# Network hosts
litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh1 -o network_name=tiz_traffic1 ip="${traf1_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh2 -o network_name=tiz_traffic2 ip="${traf2_ip[0]}"

litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh3 -o network_name=tiz_traffic1 ip="${traf1_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh4 -o network_name=tiz_traffic2 ip="${traf2_ip[1]}"

# network hosted by a bond
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh5 -o network_name=data ip="${node_ip_836_bond[0]}" 
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh6 -o network_name=data ip="${node_ipv6_836_bond_nhs[0]}"
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh7 -o network_name=data ip="${node_ip_836_bond[1]}" 
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/nh8 -o network_name=data ip="${node_ipv6_836_bond_nhs[1]}"

#DNS
litp create -t dns-client -p /ms/configs/dns_client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_A -o ipaddress=10.44.86.4 position=1
litp create -t nameserver -p /ms/configs/dns_client/nameservers/my_name_server_B -o ipaddress=2001:4860:0:1001::68 position=2


##### NAS #######
# SFS Unmanaged
# Commented out for LITPCDS-6376 

# SFS Filesystem Server 1
#litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp1 -o name="sfs1" management_ipv4="${sfs1_management_ip}" user_name='support' password_key='key-for-sfs' #pool_name="SFS_Pool"
#litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -o name="virtserv1" ipv4address="${sfs1_vip}"
#litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1 -o name="ST_Pool"


# FS unmanaged
# This FS must already exist on the SFS server
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/unmanaged1 -o export_path="${sfs_prefix}-fs1" provider="virtserv1" mount_point="/SFSunmanaged1" mount_options="soft,intr" network_name="netwrk837"
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon1/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1
#litp inherit -p /ms/file_systems/unmanaged1 -s /infrastructure/storage/nfs_mounts/unmanaged1

# FS managed
# SFS Server 1
#litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1 -o path="${sfs_prefix}-managed1" size='40M'
#litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2 -o path="${sfs_prefix}-managed2" size='40M'

#litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs1/exports/ex1         -o ipv4allowed_clients="10.44.86.194,10.44.86.195,10.44.86.196" options="rw,no_root_squash"
#litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/pl1/file_systems/mgmt_fs2/exports/ex2         -o ipv4allowed_clients="10.44.86.194,10.44.86.195,10.44.86.196" options="rw,no_root_squash"

#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1_1 -o export_path="${sfs_prefix}-managed1" provider="virtserv1" mount_point="/SFS1_managed1" mount_options="soft,intr" network_name="netwrk837"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount1_2 -o export_path="${sfs_prefix}-managed1" provider="virtserv1" mount_point="/SFS1_managed2" mount_options="soft,intr" network_name="netwrk837"

#litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1_1
#litp inherit -p /ms/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount1_2
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon1/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1_1
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon1/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount1_2
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon2/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1_1
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon2/file_systems/fs2 -s /infrastructure/storage/nfs_mounts/mount1_2


# FS managed
# SFS Server 2
#litp create -t sfs-service -p /infrastructure/storage/storage_providers/sfs_service_sp2 -o name="sfs2" management_ipv4="${sfs2_management_ip}" user_name='support' password_key='key-for-sfs'
#litp create -t sfs-virtual-server -p /infrastructure/storage/storage_providers/sfs_service_sp2/virtual_servers/vs2 -o name="virtserv2" ipv4address="${sfs2_vip}"

#litp create -t sfs-pool             -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1 -o name="SFS_Pool"

# FS managed
#litp create -t sfs-filesystem       -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1/file_systems/mgmt_fs1 -o path="/vx/ST51-managed2" size='40M'

#litp create -t sfs-export           -p /infrastructure/storage/storage_providers/sfs_service_sp2/pools/pl1/file_systems/mgmt_fs1/exports/ex1         -o ipv4allowed_clients="10.44.86.0/26" options="rw,no_root_squash"

#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/mount2_1 -o export_path="/vx/ST51-managed2" provider="virtserv2" mount_point="/SFS2_managed" mount_options="soft,intr" network_name="netwrk834"

#litp inherit -p /ms/file_systems/managed2 -s /infrastructure/storage/nfs_mounts/mount2_1
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon1/file_systems/managed2 -s /infrastructure/storage/nfs_mounts/mount2_1


# Non SFS 
#litp create -t nfs-service -p /infrastructure/storage/storage_providers/nas_service_sp1 -o name="nas1" ipv4address="${nas_management_ip}"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm1 -o export_path="${nas_prefix}/ro_unmanaged" provider="nas1" mount_point="/cluster_ro" mount_options="soft,intr" network_name="netwrk834"
#litp create -t nfs-mount -p /infrastructure/storage/nfs_mounts/nm2 -o export_path="${nas_prefix}/rw_unmanaged" provider="nas1" mount_point="/cluster_rw" mount_options="soft,intr" network_name="netwrk834"


#litp inherit -p /ms/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#litp inherit -p /ms/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon1/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon1/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon2/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
#litp inherit -p /deployments/d1/clusters/tizon/nodes/tizon2/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2


#log rotate rules
litp create -t logrotate-rule-config -p /deployments/d1/clusters/tizon/nodes/tizon1/configs/logrotate
litp create -t logrotate-rule -p /deployments/d1/clusters/tizon/nodes/tizon1/configs/logrotate/rules/messages -o name="a_messages" path="/var/log/messages" size=10M mail=stefan.ulian@ammeon.com rotate=50 copytruncate=true
#litp create -t logrotate-rule-config -p /ms/configs/logrotate
#litp create -t logrotate-rule -p /ms/configs/logrotate/rules/messages -o name="a_messages" path="/var/log/messages" size=10M mail=stefan.ulian@ammeon.com rotate=50 copytruncate=true


# private network
litp create -t network -p /infrastructure/networking/networks/tizonnet1vm -o name=tizonnet1vm subnet="${net1vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/tizonnet2vm -o name=tizonnet2vm subnet="${net2vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/tizonnet3vm -o name=tizonnet3vm subnet="${net3vm_subnet}"
litp create -t network -p /infrastructure/networking/networks/tizonnet4vm -o name=tizonnet4vm subnet="${net4vm_subnet}"

# Bridge for ms for private network
#litp create -t vlan -p /ms/network_interfaces/bond1_333 -o device_name=bond1.333 bridge=br333
#litp create -t bridge -p /ms/network_interfaces/br333 -o device_name=br333 network_name=tizonnet1vm ipaddress="${net1vm_ip_ms}"

#litp create -t vlan -p /ms/network_interfaces/bond1_444 -o device_name=bond1.444 bridge=br444
#litp create -t bridge -p /ms/network_interfaces/br444 -o device_name=br444 network_name=tizonnet2vm ipaddress="${net2vm_ip_ms}"

#litp create -t vlan -p /ms/network_interfaces/bond1_555 -o device_name=bond1.555 bridge=br555
#litp create -t bridge -p /ms/network_interfaces/br555 -o device_name=br555 network_name=tizonnet3vm ipaddress="${net3vm_ip_ms}"

#litp create -t vlan -p /ms/network_interfaces/bond1_665 -o device_name=bond1.665 bridge=br665
#litp create -t bridge -p /ms/network_interfaces/br665 -o device_name=br665 network_name=tizonnet4vm ipaddress="${net4vm_ip_ms}"



# Bridge for nodes for private network
litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_333 -o device_name=bond1.333 bridge=br333
litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_333 -o device_name=bond1.333 bridge=br333
litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/br333 -o device_name=br333 network_name=tizonnet1vm ipaddress="${net1vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/br333 -o device_name=br333 network_name=tizonnet1vm ipaddress="${net1vm_ip[1]}"

litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_444 -o device_name=bond1.444 bridge=br444
litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_444 -o device_name=bond1.444 bridge=br444
litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/br444 -o device_name=br444 network_name=tizonnet2vm ipaddress="${net2vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/br444 -o device_name=br444 network_name=tizonnet2vm ipaddress="${net2vm_ip[1]}"

litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_555 -o device_name=bond1.555 bridge=br555
litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_555 -o device_name=bond1.555 bridge=br555
litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/br555 -o device_name=br555 network_name=tizonnet3vm ipaddress="${net3vm_ip[0]}"
litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/br555 -o device_name=br555 network_name=tizonnet3vm ipaddress="${net3vm_ip[1]}"

#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/bond1_665 -o device_name=bond1.665 bridge=br665
#litp create -t vlan -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/bond1_665 -o device_name=bond1.665 bridge=br665
#litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon1/network_interfaces/br665 -o device_name=br665 network_name=net4vm ipaddress="${net4vm_ip[0]}"
#litp create -t bridge -p /deployments/d1/clusters/tizon/nodes/tizon2/network_interfaces/br665 -o device_name=br665 network_name=net4vm ipaddress="${net4vm_ip[1]}"
# Cluster 1 - VMs

# Add vcs hosts

litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net1vm_1 -o network_name=tizonnet1vm ip="${net1vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net1vm_2 -o network_name=tizonnet1vm ip="${net1vm_ip[1]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net2vm_1 -o network_name=tizonnet2vm ip="${net2vm_ip[0]}"
litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net2vm_2 -o network_name=tizonnet2vm ip="${net2vm_ip[1]}"
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net3vm_1 -o network_name=tizonnet3vm ip="${net3vm_ip[0]}"
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net3vm_2 -o network_name=tizonnet3vm ip="${net3vm_ip[1]}"
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net4vm_1 -o network_name=tizonnet4vm ip="${net4vm_ip[0]}"
#litp create -t vcs-network-host -p /deployments/d1/clusters/tizon/network_hosts/net4vm_2 -o network_name=tizonnet4vm ip="${net4vm_ip[1]}"




# Create the md5 checksum file
/usr/bin/md5sum /var/www/html/images/image.qcow2 | cut -d ' ' -f 1 > /var/www/html/images/image.qcow2.md5


for (( i=1; i<5; i++ )); do

   if (($i % 2)); then
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://10.44.235.61/images/image.qcow2"
   else
      litp create -t vm-image -p /software/images/image${i} -o name="STvm${i}" source_uri="http://ms1dot61/images/image.qcow2"
   fi

# litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=$((2**i)) ram=4096M internal_status_check=on cleanup_command="/sbin/service STvmserv$i force-stop"
  litp create -t vm-service -p /software/services/vmservice${i} -o service_name="STvmserv${i}" image_name="STvm${i}" cpus=4 ram=4096M internal_status_check=on cleanup_command="/sbin/service STvmserv$i force-stop"
   if (($i % 2)); then 
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/tizon/services/SG_STvm${i} -o name="PL_vmSG${i}" active=2 standby=0 node_list='tizon1,tizon2' online_timeout=300
#      litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=120 status_timeout=120 restart_limit=4 startup_retry_limit=2
      litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=60 status_timeout=60 restart_limit=4 startup_retry_limit=2

   else
      litp create -t vcs-clustered-service -p /deployments/d1/clusters/tizon/services/SG_STvm${i} -o name="FO_vmSG${i}" active=1 standby=1 node_list='tizon1,tizon2' online_timeout=300
#      litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=120 status_timeout=120 restart_limit=4 startup_retry_limit=2	
      litp create -t ha-service-config -p /deployments/d1/clusters/tizon/services/SG_STvm${i}/ha_configs/vm_hc -o status_interval=60 status_timeout=60 restart_limit=4 startup_retry_limit=2    

   fi

 litp inherit -p /deployments/d1/clusters/tizon/services/SG_STvm${i}/applications/vmservice${i} -s /software/services/vmservice${i}

done

#Adding nfs shares to vm's

#litp create -t vm-nfs-mount -p /software/services/vmservice1/vm_nfs_mounts/mount1 -o mount_point="/nfs_A" mount_options=soft,defaults device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_A
#litp create -t vm-nfs-mount -p /software/services/vmservice1/vm_nfs_mounts/mount2 -o mount_point="/nfs_B" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_B
#litp create -t vm-nfs-mount -p /software/services/vmservice1/vm_nfs_mounts/mount3 -o mount_point="/nfs_C" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_C

#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount1 -o mount_point="/nfs_A" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_A
#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount2 -o mount_point="/nfs_B" mount_options=soft,defaults device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_B
#litp create -t vm-nfs-mount -p /software/services/vmservice2/vm_nfs_mounts/mount3 -o mount_point="/nfs_C" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_C

#litp create -t vm-nfs-mount -p /software/services/vmservice3/vm_nfs_mounts/mount1 -o mount_point="/nfs_A" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_A
#litp create -t vm-nfs-mount -p /software/services/vmservice3/vm_nfs_mounts/mount2 -o mount_point="/nfs_B" device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_B
#litp create -t vm-nfs-mount -p /software/services/vmservice3/vm_nfs_mounts/mount3 -o mount_point="/nfs_C" mount_options=soft,defaults device_path=10.44.86.4:/home/admin/ST/nfs_share_dir_51/dir_share_51_C


###################
## VMS
##################

#litp update -p /software/services/vmservice1/vm_network_interfaces/vm_nic1 -o mac_prefix="AA:AA:AA"

litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=tizonnet1vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.10,10.46.81.11 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=tizonnet2vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.80,10.46.81.81 #gateway="${net2vm_gw[0]}"
#litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=tizonnet3vm
#litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.140,10.46.81.141 #gateway="${net3vm_gw[0]}"
#litp create -t vm-network-interface -p /software/services/vmservice1/vm_network_interfaces/vm_nic4 -o device_name=eth3 host_device=br665 network_name=tizonnet4vm
#litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm1/applications/vmservice1/vm_network_interfaces/vm_nic4 -o ipaddresses=10.46.81.200,10.46.81.201 #gateway="${net4vm_gw[0]}"


litp create -t vm-network-interface -p /software/services/vmservice2/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=tizonnet1vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm2/applications/vmservice2/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.12 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice2/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=tizonnet2vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm2/applications/vmservice2/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.82 #gateway="${net2vm_gw[0]}"
#litp create -t vm-network-interface -p /software/services/vmservice2/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=tizonnet3vm
#litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm2/applications/vmservice2/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.142 #gateway="${net3vm_gw[0]}"




litp create -t vm-network-interface -p /software/services/vmservice3/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=tizonnet1vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm3/applications/vmservice3/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.13,10.46.81.14 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice3/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=tizonnet2vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm3/applications/vmservice3/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.84,10.46.81.85 #gateway="${net2vm_gw[0]}"
#litp create -t vm-network-interface -p /software/services/vmservice3/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=tizonnet3vm
#litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm3/applications/vmservice3/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.143,10.46.81.144 #gateway="${net3vm_gw[0]}"



litp create -t vm-network-interface -p /software/services/vmservice4/vm_network_interfaces/vm_nic1 -o device_name=eth0 host_device=br333 network_name=tizonnet1vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm4/applications/vmservice4/vm_network_interfaces/vm_nic1 -o ipaddresses=10.46.81.15 gateway="${net1vm_gw[0]}"
litp create -t vm-network-interface -p /software/services/vmservice4/vm_network_interfaces/vm_nic2 -o device_name=eth1 host_device=br444 network_name=tizonnet2vm
litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm4/applications/vmservice4/vm_network_interfaces/vm_nic2 -o ipaddresses=10.46.81.86 #gateway="${net2vm_gw[0]}"
#litp create -t vm-network-interface -p /software/services/vmservice4/vm_network_interfaces/vm_nic3 -o device_name=eth2 host_device=br555 network_name=tizonnet3vm
#litp update -p  /deployments/d1/clusters/tizon/services/SG_STvm4/applications/vmservice4/vm_network_interfaces/vm_nic3 -o ipaddresses=10.46.81.145 #gateway="${net3vm_gw[0]}"


#litp update -p /deployments/d1/clusters/tizon/services/SG_STvm1 -o dependency_list=SG_STvm2,SG_STvm3
#litp update -p /deployments/d1/clusters/tizon/services/SG_STvm3 -o dependency_list=SG_STvm4

### Add DHCP server for vm's
litp create -t dhcp-service -p /software/services/dhcp -o service_name="dhcp"

litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm1 -o network_name=tizonnet1vm
litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm2 -o network_name=tizonnet2vm
#litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm3 -o network_name=tizonnet3vm
#litp create -t dhcp-subnet -p /software/services/dhcp/subnets/vm4 -o network_name=tizonnet4vm

litp create -t dhcp-range -p /software/services/dhcp/subnets/vm1/ranges/r1 -o start=10.46.81.1 end=10.46.81.63
litp create -t dhcp-range -p /software/services/dhcp/subnets/vm2/ranges/r1 -o start=10.46.81.64 end=10.46.81.127
#litp create -t dhcp-range -p /software/services/dhcp/subnets/vm3/ranges/r1 -o start=10.46.81.128 end=10.46.81.191
#litp create -t dhcp-range -p /software/services/dhcp/subnets/vm4/ranges/r1 -o start=10.46.81.192 end=10.46.81.254

# add ssh keys to vm's temp

litp create -t vm-ssh-key -p /software/services/vmservice2/vm_ssh_keys/support_key1 -o ssh_key="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuLmfvcm6mOieGb6wSs+L1iSoIsblK1xx0f8YM1pnTuXqTdSxvtex+A9rCvGS8paBjzA665EcOtOh81D3B0HxgVj2p4PYWEWtzpCGyGNbUvOuwoDViHKe2ubtI6m6CYVz70GGTyKdlEwyvXLTkk0rZo8LGVAxUkdnuACjDyqAWPKtIUsmz1L6dlXx5dv6spfYq1wZDBhocUux2vk7RrHY2fOfOLXnYqDm6d5T7Wv5v2v/Kt2vdaHt556ZMa06bNStcXn+7CGJ9Pr+bFy0kid7YKypbFFKeS2o3HwGo4vqz+G8hUGakaZmxRznEdQSx1gAxZ6vk0ueqk6ALtV5IVqD1w== adrian.vornic@1VGS45J"

#litp create -t vm-ssh-key -p /software/services/vmservice1/vm_ssh_keys/support_key1 -o ssh_key="cucu rucu cucu"

litp create_plan
