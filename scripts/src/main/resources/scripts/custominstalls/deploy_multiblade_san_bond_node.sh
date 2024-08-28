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
#function litp(){
#    command litp "$@" 2>&1
#    retval=( $(echo "$?") )
#    if [ $retval -ne 0 ]
#    then
#        exit 1
#    fi
#}



litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs support support

############################################################################
# SOFTWARE
############################################################################

# OS PROFILE
litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/

# SOFTWARE ITEMS
litp create -p /software/items/openjdk -t package -o name=java-1.7.0-openjdk
litp create -p /software/items/dovecot -t package -o name=dovecot release=7.el6_5.1 version=2.0.9 epoch=1
litp create -p /software/items/sentinel -t package -o name=EXTRlitpsentinellicensemanager_CXP9031488

# SERVICES
litp create -p /software/items/ntp1 -t ntp-service
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="ntpAlias1"
litp create -p /software/items/ntp1/servers/server1 -t ntp-server -o server="${ntp_ip[1]}"
litp create  -p /software/services/sentinel -t service -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

############################################################################
# DEPLOYMENTS
############################################################################

litp create -p /deployments/d1 -t deployment

############################################################################
# INFRASTRUCTURE
############################################################################

# STORAGE PROFILE 1, 1 VOLUME GROUP 2 DISKS
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/data1 -t file-system -o type=ext4 mount_point=/data1 size=2G snap_size=0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal2 -t physical-device -o device_name=hd1

# STORAGE PROFILE 1, 2 VOLUME GROUPS, VXVM DISKS
litp create -p /infrastructure/storage/storage_profiles/profile_2 -t storage-profile -o volume_driver='vxvm'
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm -t volume-group -o volume_group_name=vg1_vxvm
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm/file_systems/data1_vxvm -t file-system -o type=vxfs mount_point=/data2 size=2G snap_size=50
litp create -p /infrastructure/storage/storage_profiles/profile_2/volume_groups/vg1_vxvm/physical_devices/internal -t physical-device -o device_name=hd2

#litp create -p /infrastructure/storage/storage_profiles/profile_3 -t storage-profile -o volume_driver='vxvm'
#litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg2_vxvm -t volume-group -o volume_group_name=vg2_vxvm
#litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg2_vxvm/file_systems/data2_vxvm -t file-system -o type=vxfs mount_point=/data3 size=100M snap_size=100
#litp create -p /infrastructure/storage/storage_profiles/profile_3/volume_groups/vg2_vxvm/physical_devices/internal -t physical-device -o device_name=hd3

# CREATE BLADE FOR SYSTEM 1 - MS
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # DISK CREATION FOR SYSTEMS - PEER NODES
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    # DISK SETUP
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk1 -t disk -o name=hd1 size=9G bootable=false uuid="${node_disk1_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk2 -t disk -o name=hd2 size=10G bootable=false uuid="${node_vxvm_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk3 -t disk -o name=hd3 size=400M bootable=false uuid="${node_vxvm2_uuid[$i]}"
    # BMC SETUP FOR PXE BOOTING BLADES
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

##### NETWORKING SETUP #####

# ROUTES IPV4
litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"

# ROUTES IPV6
litp create -p /infrastructure/networking/routes/default_ipv6 -t route6 -o subnet=::/0 gateway="${ipv6_gateway}"

# NEW GATEWAY FOR TRAFFIC NETWORK
litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet=${traffic_network2_gw_subnet} gateway=${traffic_network2_gw}

# SETUP MGMT NETWORK
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true

# HEARTBEAT NETWORKS FOR VCS
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2

# TRAFFIC NETWORKS FOR VCS
litp create -p /infrastructure/networking/networks/traffic1 -t network -o name='traffic1' subnet="${traffic_network1_subnet}"
litp create -p /infrastructure/networking/networks/traffic2 -t network -o name='traffic2' subnet="${traffic_network2_subnet}"
litp create -p /infrastructure/networking/networks/traffic3 -t network -o name='traffic3' subnet="${traffic_network3_subnet}"

##### STORAGE SETUP #####


# STORAGE PROVIDER - SFS
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1 -t sfs-service -o name="sfs1_init" management_ipv4="${sfs_management_ip}" user_name="${sfs_username}" password_key="key-for-sfs"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -t sfs-virtual-server -o name="virtserv1" ipv4address="${sfs_vip}"

# UNMANAGED SFS POOLS
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1 -t sfs-pool -o name="${sfs_pool1}"

# CREATE MANAGED SFS FILESYSTEM
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs1 -t sfs-filesystem -o path="${managedfs1}" size="50M"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs2 -t sfs-filesystem -o path="${managedfs2}" size="50M"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs3 -t sfs-filesystem -o path="${managedfs3}" size="50M"

# CREATE MANAGED SHARES ON SFS
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs1/exports/export1 -t sfs-export -o ipv4allowed_clients="${ms_subnet}" options="rw,no_root_squash"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs2/exports/export2 -t sfs-export -o ipv4allowed_clients="${node_ip[0]},${node_ip[1]}" options="ro,root_squash"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs3/exports/export3 -t sfs-export -o ipv4allowed_clients="${ms_subnet}" options="rw,no_wdelay,no_root_squash"

# UNMANAGED SFS MOUNTS
litp create -p /infrastructure/storage/nfs_mounts/mount1 -t nfs-mount -o export_path="${sfs_unmanaged_prefix}" provider="virtserv1" mount_point="/cluster1" mount_options="soft,intr" network_name="mgmt"

# MANAGED SFS MOUNTS
litp create -p /infrastructure/storage/nfs_mounts/mount2 -t nfs-mount -o export_path="${managedfs1}" provider="virtserv1" mount_point="/mfs_cluster1" mount_options="soft,intr" network_name="mgmt"
litp create -p /infrastructure/storage/nfs_mounts/mount3 -t nfs-mount -o export_path="${managedfs2}" provider="virtserv1" mount_point="/mfs_cluster2" mount_options="soft,intr" network_name="mgmt"
litp create -p /infrastructure/storage/nfs_mounts/mount4 -t nfs-mount -o export_path="${managedfs3}" provider="virtserv1" mount_point="/mfs_cluster3" mount_options="soft,intr" network_name="mgmt"

# STORAGE PROVIDER - NFS
litp create -p /infrastructure/storage/storage_providers/sp1 -t nfs-service -o name="nfs1_init" ipv4address="${nfs_management_ip}"

# NFS MOUNTS
litp create -p /infrastructure/storage/nfs_mounts/nm1 -t nfs-mount -o export_path="${nfs_prefix}/ro_unmanaged" provider="nfs1_init" mount_point="/cluster_ro" mount_options="soft,intr" network_name="mgmt"
litp create -p /infrastructure/storage/nfs_mounts/nm2 -t nfs-mount -o export_path="${nfs_prefix}/rw_unmanaged" provider="nfs1_init" mount_point="/cluster_rw" mount_options="soft,intr" network_name="mgmt"

############################################################################
# MS
############################################################################

# SET MS HOSTNAME - SET FROM RHEL/LITP INSTALLATION
litp update -p /ms -o hostname="$ms_host"

# CREATE MS SYSTEM
litp inherit -p /ms/system -s /infrastructure/systems/sys1

# MS SERVICES
litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /ms/services/sentinel -t service -o service_name=sentinel

# MS ROUTES
litp inherit -p /ms/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /ms/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

if [[ $blade_type == *DL380-G9* ]]
then
    litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt
else
    # MS NETWORK DEVICE SETUP - USING BONDED DEVICES
    litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bondmgmt
    litp create -p /ms/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bondmgmt

    # SET UP BONDING FOR MGMT NETWORK
    litp create -p /ms/network_interfaces/b0 -t bond -o device_name=bondmgmt ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt miimon=100

    # SETUP A BRIDGE ON THE MGMT NETWORK
    #litp create -p /ms/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt stp=true

    # VLAN ON THE BRIDGE
    #litp create -p /ms/network_interfaces/b0_vlan -t vlan -o device_name=bondmgmt.${ms_vlan_id} bridge=br0 
fi

# SETUP ALIAS ON MS USING NTP AS AN EXAMPLE
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names="ntpAlias1" address="${ntp_ip[1]}"

# FIREWALL SETUP FOR  MS
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"
litp create -p /ms/configs/fw_config_init/rules/fw_icmpv6 -t firewall-rule -o name="099 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

# SYSCTRL PARAMS FOR MS
litp create -p /ms/configs/mynodesysctl -t sysparam-node-config
litp create -p /ms/configs/mynodesysctl/params/sysctl_MS01 -t sysparam -o key=net.ipv4.udp_mem value="24794401 33059201 49588801"

# NAS MOUNTS FOR MS
litp inherit -p /ms/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1
litp inherit -p /ms/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
litp inherit -p /ms/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2
litp inherit -p /ms/file_systems/mfs1 -s /infrastructure/storage/nfs_mounts/mount2
litp inherit -p /ms/file_systems/mfs2 -s /infrastructure/storage/nfs_mounts/mount4

# DNS FOR MS
litp create -p /ms/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -p /ms/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress="${nameserver_ip}" position=1

# MS ITEMS
litp inherit -p /ms/items/java -s /software/items/openjdk
litp inherit -p /ms/items/ntp -s /software/items/ntp1
litp inherit -p /ms/items/sentinel -s /software/items/sentinel

# LOGROTATE RULES FOR /var/log/messages
litp create -p /ms/configs/logrotate -t logrotate-rule-config
litp create -p /ms/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

############################################################################
# CLUSTERING SETUP
############################################################################

# CLUSTER CREATION - VCS
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=traffic2 llt_nets='hb1,hb2' cluster_id="${cluster_id}" default_nic_monitor="mii"

# CLUSTER CONFIGURATION FOR FILEWALLS
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

# INDIVIDUAL NODE SETUP

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # HOSTNAME SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    # INHERIT SYSTEM SETUP FROM ABOVE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s  /infrastructure/systems/sys$(($i+2))

    # CREATE OS PROFILE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    # CREATE STORAGE PROFILE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 
    
    # INHERIT SPECIFIC SOFTWARE ITEMS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/dovecot -s /software/items/dovecot

    # LOG ROTATE RULES FOR THE NODE
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate -t logrotate-rule-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

    ##### NETWORK SETUP FOR EACH NIC #####

    # GATEWAY SETUP FOR NODE
    litp create -p /infrastructure/networking/routes/traffic3_gw_n$(($i+1)) -t route -o subnet=${traffic_network3_gw_subnet} gateway="${node_ip_4[$i]}"

    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" master=bondmgmt
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" master=bondmgmt
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/b0 -t bond -o device_name=bondmgmt ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6_00[$i]}" network_name=mgmt miimon=100

    # HEARTBEAT NETWORK SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
    # TRAFFIC NETWORKS
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name='traffic1' ipaddress="${node_ip_2[$i]}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name='traffic2' ipaddress="${node_ip_3[$i]}" 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_eth6_mac[$i]}" network_name='traffic3' ipaddress="${node_ip_4[$i]}"

    # ROUTE SETUP
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

    # GATEWAY SETUP FOR NODES
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n$(($i+1))

    # CREATE FIREWALL SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=099 icmpipv6' proto=ipv6-icmp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

    # UNMANAGED SFS MOUNTS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/fs1 -s /infrastructure/storage/nfs_mounts/mount1

    # MANAGED SFS MOUNTS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mfs1 -s /infrastructure/storage/nfs_mounts/mount2
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mfs2 -s /infrastructure/storage/nfs_mounts/mount3

    # SYSCTRL PARAMS FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/init_config -t sysparam-node-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/init_config/params/sysctrl_01 -t sysparam -o key="net.ipv4.tcp_wmem" value="4096 65536 16777215"
	
    # DNS SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.4 position=1

    # NODE SERVICES
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/services/sentinel -s /software/services/sentinel
done

# VXVM SETUP FOR CLUSTER
litp inherit -p /deployments/d1/clusters/c1/storage_profile/vxvm_profile -s /infrastructure/storage/storage_profiles/profile_2 

# FENCING DISKS SETUP FOR CLUSTER
litp create -p /deployments/d1/clusters/c1/fencing_disks/fd1 -t disk -o uuid=${fencing_disk1_uuid} size=100M name=fencing_disk_1
litp create -p /deployments/d1/clusters/c1/fencing_disks/fd2 -t disk -o uuid=${fencing_disk2_uuid} size=100M name=fencing_disk_2
litp create -p /deployments/d1/clusters/c1/fencing_disks/fd3 -t disk -o uuid=${fencing_disk3_uuid} size=100M name=fencing_disk_3

# CLUSTER NETWORK SETUP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh1 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host1}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh2 -t vcs-network-host -o network_name="mgmt"     ip="${ms_ip}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh3 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host3}" 
litp create -p /deployments/d1/clusters/c1/network_hosts/nh4 -t vcs-network-host -o network_name="traffic1" ip="${ms_ip}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh5 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host5}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh6 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host6}" 
litp create -p /deployments/d1/clusters/c1/network_hosts/nh7 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host7}" 
litp create -p /deployments/d1/clusters/c1/network_hosts/nh8 -t vcs-network-host -o network_name="traffic2" ip="${vcs_network_host8}" 
litp create -p /deployments/d1/clusters/c1/network_hosts/nh9 -t vcs-network-host -o network_name="traffic2" ip="${ms_ipv6_00_noprefix}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh10 -t vcs-network-host -o network_name="traffic2" ip="${vcs_network_host10}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh11 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host11}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh12 -t vcs-network-host -o network_name=traffic1 ip=${traffic_network1_gw}
litp create -p /deployments/d1/clusters/c1/network_hosts/nh13 -t vcs-network-host -o network_name=traffic1 ip="${node_ip_2[1]}" #NOTE HARDCODED TO 2nd NODE IP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh14 -t vcs-network-host -o network_name=traffic2 ip=${traffic_network2_gw}
litp create -p /deployments/d1/clusters/c1/network_hosts/nh15 -t vcs-network-host -o network_name=traffic2 ip="${node_ip_3[1]}" #NOTE HARDCODED TO 2nd NODE IP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh16 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host12}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh17 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host13}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh18 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host14}"


########## VCS SERVICE GROUPS - CLUSTER SERVICES #############

# FAILOVER SERVICE GROUP
FO_SG_pkg=cups

litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg" -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs1 online_timeout=45 node_list='n2,n1' dependency_list=httpd
litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/ha_configs/conf1 -t ha-service-config -o status_interval=30 status_timeout=30 restart_limit=10 startup_retry_limit=3
litp create -p /software/items/"$FO_SG_pkg" -t package -o name="$FO_SG_pkg"
litp create -p /software/services/"$FO_SG_pkg" -t service -o service_name="$FO_SG_pkg"
litp inherit -p /software/services/"$FO_SG_pkg"/packages/pkg1 -s /software/items/"$FO_SG_pkg"
litp inherit -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/applications/"$FO_SG_pkg" -s /software/services/"$FO_SG_pkg"
litp create  -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_pl1_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_pl1_vip2}" network_name=traffic3
litp inherit -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/vxvm_profile/volume_groups/vg1_vxvm/file_systems/data1_vxvm

# PARALLEL SERVICE GROUP
PL_SG_pkg=httpd

litp create -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg" -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs node_list='n1,n2'
litp create -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/ha_configs/conf1 -t ha-service-config -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2
litp create -p /software/items/"$PL_SG_pkg" -t package -o name="$PL_SG_pkg" epoch=0
litp create -p /software/services/"$PL_SG_pkg" -t service -o service_name="$PL_SG_pkg"
litp inherit -p /software/services/"$PL_SG_pkg"/packages/pkg1 -s /software/items/"$PL_SG_pkg"
litp inherit -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/applications/"$PL_SG_pkg" -s /software/services/"$PL_SG_pkg"
litp create  -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_fo1_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_fo1_vip2}" network_name=traffic3

###############################################################
# CREATE PLAN
###############################################################

litp create_plan
