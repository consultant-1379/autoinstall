#!/bin/bash
#
# Sample LITP multi-blade deployment ('local disk' version)
#
# Usage:
#   deploy_multiblade_local.sh <CLUSTER_SPEC_FILE>
#

if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"


set -x
function litp(){
    command litp "$@" 2>&1
    retval=( $(echo "$?") )
    if [ $retval -ne 0 ]
    then
        exit 1
    fi
}



# Set iLo password
# litpcrypt set key-for-root root ilopassword - where ilopassword is the password for the iLo
litpcrypt set key-for-user no-user 'ignored'
litpcrypt set key-for-sfs support symantec
############################################################################
# SOFTWARE
############################################################################

# OS PROFILE
litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/

# SOFTWARE ITEMS
litp create -p /software/items/openjdk -t package -o name=java-1.7.0-openjdk
litp create -p /software/items/dovecot -t package -o name=dovecot release=22.el6 version=2.0.9 epoch=1
litp create -p /software/items/sentinel -t package -o name=EXTRlitpsentinellicensemanager_CXP9031488

# SERVICES
litp create -p /software/items/ntp1 -t ntp-service
litp create -p /software/items/ntp1/servers/server0 -t ntp-server -o server="ntpAlias1"
litp create -p /software/services/sentinel -t service -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel
litp create -p /software/services/dhcp -t dhcp-service -o service_name=dhcp
############################################################################
# DEPLOYMENTS
############################################################################

litp create -p /deployments/d1 -t deployment

############################################################################
# INFRASTRUCTURE
############################################################################

# STORAGE PROFILE 1, 1 VOLUME GROUP 1 DISK
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=16G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=sda

# CREATE BLADE FOR SYSTEM 1 - MS
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # DISK CREATION FOR SYSTEMS - PEER NODES
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    # DISK SETUP
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=sda size=40G bootable=true uuid="${node_disk_uuid[$i]}"
    # BMC SETUP FOR PXE BOOTING BLADES
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o username=no-user password_key=key-for-user ipaddress=${node_ip[$i]}
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
#litp create -p /infrastructure/networking/networks/traffic4_v6 -t network -o name='traffic4_v6' subnet="${traffic_network4_subnet}"

# DHCP NETWORK
litp create -p /infrastructure/networking/networks/dhcp_network -t network -o name=dhcp_network subnet="${dhcp_subnet_1}"

# BRIDGED NETWORK
#litp create -p /infrastructure/networking/networks/bridge_network -t network -o name=bridge_network subnet="${bridge_subnet_1}"

# VM NETWORK THAT WILL USE THE DHCP NETWORK
litp create -p /software/services/dhcp/subnets/vmpools -t dhcp-subnet -o network_name=dhcp_network
litp create -p /software/services/dhcp/subnets/vmpools/ranges/r1 -t dhcp-range -o start="${dhcp_range_1_start}" end="${dhcp_range_1_end}"

##### STORAGE SETUP #####

# STORAGE PROVIDER - SFS
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1 -t sfs-service -o name="sfs1_init" management_ipv4="${sfs_management_ip}" user_name="${sfs_username}" password_key="key-for-sfs"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/virtual_servers/vs1 -t sfs-virtual-server -o name="virtserv1" ipv4address="${sfs_vip}"

# UNMANAGED SFS POOLS
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1 -t sfs-pool -o name="${sfs_pool1}"

# CREATE MANAGED SFS FILESYSTEM
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs1 -t sfs-filesystem -o path="${managedfs1}" size="50M"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs2 -t sfs-filesystem -o path="${managedfs2}" size="50M"

# CREATE MANAGED SHARES ON SFS
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs1/exports/export1 -t sfs-export -o ipv4allowed_clients="${node_ip[0]},${node_ip[1]}" options="ro,root_squash"
litp create -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs2/exports/export2 -t sfs-export -o ipv4allowed_clients="${ms_subnet}" options="rw,no_wdelay,no_root_squash"

# MANAGED SFS MOUNTS
litp create -p /infrastructure/storage/nfs_mounts/mount2 -t nfs-mount -o export_path="${managedfs1}" provider="virtserv1" mount_point="/mfs_cluster1" mount_options="soft,intr" network_name="mgmt"
litp create -p /infrastructure/storage/nfs_mounts/mount3 -t nfs-mount -o export_path="${managedfs2}" provider="virtserv1" mount_point="/mfs_cluster2" mount_options="soft,intr" network_name="mgmt"

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

# MS NETWORK DEVICE SETUP - USING BONDED DEVICES
litp create -p /ms/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${ms_eth0_mac}" master=bondmgmt
litp create -p /ms/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${ms_eth1_mac}" master=bondmgmt

# SET UP BONDING FOR MGMT NETWORK
litp create -p /ms/network_interfaces/b0 -t bond -o device_name=bondmgmt ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt miimon=100
##ADD 
#litp create -p /ms/network_interfaces/b0 -t bond -o device_name=bondmgmt
#litp create -t vlan -p /ms/network_interfaces/b0_834 -o device_name=bondmgmt.834 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

# SETUP ALIAS ON MS USING NTP AS AN EXAMPLE
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names="ntpAlias1" address="${ntp_ip[1]}"

# FIREWALL SETUP FOR  MS
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"
litp create -p /ms/configs/fw_config_init/rules/fw_icmpv6 -t firewall-rule -o name="101 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name'=011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name'=001 nfstcp' dport=111,2049,4001,12987 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
litp create -p /ms/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='053 dnsudp' dport=53 proto=udp

# SYSCTRL PARAMS FOR MS
litp create -p /ms/configs/mynodesysctl -t sysparam-node-config
litp create -p /ms/configs/mynodesysctl/params/sysctl_MS01 -t sysparam -o key=net.ipv4.udp_mem value="24794401 33059201 49588801"

# NAS MOUNTS FOR MS
litp inherit -p /ms/file_systems/mfs1 -s /infrastructure/storage/nfs_mounts/mount3

# DNS FOR MS
litp create -p /ms/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -p /ms/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=${nameserver_ip} position=1

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
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets='hb1,hb2' cluster_id="${cluster_id}"

# CLUSTER CONFIGURATION FOR FILEWALLS
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c1/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

# INDIVIDUAL NODE SETUP

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    # GATEWAY SETUP FOR NODE

    # HOSTNAME SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"

    # INHERIT SYSTEM SETUP FROM ABOVE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -s /infrastructure/systems/sys$(($i+2))

    # CREATE OS PROFILE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -s /software/profiles/os_prof1

    # CREATE STORAGE PROFILE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1

    # INHERIT SPECIFIC SOFTWARE ITEMS
    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/java -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/dovecot -s /software/items/dovecot

    # LOG ROTATE RULES FOR THE NODE
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate -t logrotate-rule-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

    ##### NETWORK SETUP FOR EACH NIC #####

    # GATEWAY SETUP FOR NODE
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw

    # BRIDGE ETH0
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" bridge='br0'
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6_00[$i]}" forwarding_delay=0 network_name='mgmt'

    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6_00[$i]}" forwarding_delay=0 network_name='mgmt'

    # HEARTBEAT NETWORK SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_eth2_mac[$i]}" network_name=hb1
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2
    
    # TRAFFIC NETWORKS
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name='traffic1' ipaddress="${node_ip_2[$i]}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name='traffic2' ipaddress="${node_ip_3[$i]}"

    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br7 -t bridge -o device_name=br7 forwarding_delay=0 network_name=traffic4_v6
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if7 -t eth -o bridge=br7 device_name=eth7 macaddress="${node_eth7_mac[$i]}"

    # DHCP NETWORKS
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if6 -t eth -o bridge='br6' device_name=eth6 macaddress="${node_eth6_mac[$i]}"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br6 -t bridge -o device_name='br6' forwarding_delay=0 network_name=dhcp_network ipaddress="${dhcp_ip_1[$i]}"

    # BRIDGED NETWORK
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if7 -t eth -o device_name=eth7 macaddress="${node_eth7_mac[$i]}" bridge='br7'
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br7 -t bridge -o device_name=br7 forwarding_delay=0 network_name='bridged'

    # ROUTE SETUP
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

    # CREATE FIREWALL SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001,12987 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o name='101 icmpipv6' proto="ipv6-icmp"
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dhcpudp -t firewall-rule  -o name="400 dhcp" proto="udp" dport=67 provider=iptables
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dhcpsynctcp -t firewall-rule  -o name="401 dhcpsync" proto="tcp" dport=647 provider=iptables
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='053 dnsudp' dport=53 proto=udp
    
    # MANAGED SFS MOUNTS
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/file_systems/mfs2 -s /infrastructure/storage/nfs_mounts/mount2

    # SYSCTRL PARAMS FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/init_config -t sysparam-node-config
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/init_config/params/sysctrl_01 -t sysparam -o key="net.ipv4.tcp_wmem" value="4096 65536 16777215"

    # DNS SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.14 position=1

    # NODE SERVICES
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/services/sentinel -s /software/services/sentinel

    # NTP ALIAS CONFIG
    #litp create -t alias-node-config -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/node_alias_config
    #litp create -t alias -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/node_alias_config/aliases/ntp_alias1 -o alias_names=ntpAlias1 address="${ntp_ip[1]}"


done

# EXTRA NODE CONFIG FOR DHCP

litp inherit -p /deployments/d1/clusters/c1/nodes/n1/services/dhcp -s /software/services/dhcp
litp inherit -p /deployments/d1/clusters/c1/nodes/n2/services/dhcp -s /software/services/dhcp -o primary=false

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
litp create -p /deployments/d1/clusters/c1/network_hosts/nh12 -t vcs-network-host -o network_name=traffic1 ip=${traffic_network1_gw}
litp create -p /deployments/d1/clusters/c1/network_hosts/nh13 -t vcs-network-host -o network_name=traffic1 ip="${node_ip_2[1]}" #NOTE HARDCODED TO 2nd NODE IP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh14 -t vcs-network-host -o network_name=traffic2 ip=${traffic_network2_gw}
litp create -p /deployments/d1/clusters/c1/network_hosts/nh15 -t vcs-network-host -o network_name=traffic2 ip="${node_ip_3[1]}" #NOTE HARDCODED TO 2nd NODE IP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh16 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host12}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh17 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host13}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh18 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host14}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh19 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host15}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh20 -t vcs-network-host -o network_name=dhcp_network ip="${dhcp_ip_1[0]}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh21 -t vcs-network-host -o network_name=dhcp_network ip="${dhcp_ip_1[1]}"

########## VCS SERVICE GROUPS - CLUSTER SERVICES #############

# FAILOVER SERVICE GROUP
FO_SG_pkg=(cups)
for (( x=0; x<${#FO_SG_pkg[@]}; x++ )); do 
    litp create -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}" -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs$(($x+1)) offline_timeout=10 online_timeout=10 node_list='n2,n1' dependency_list=httpd
    litp create -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}" -t lsb-runtime -o name="${FO_SG_pkg[$x]}" service_name="${FO_SG_pkg[$x]}" status_interval=100
    litp create -p /software/items/"${FO_SG_pkg[$x]}" -t package -o name="${FO_SG_pkg[$x]}"
    litp inherit -p /deployments/d1/clusters/c1/services/"${FO_SG_pkg[$x]}"/runtimes/"${FO_SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${FO_SG_pkg[$x]}"
done

# PARALLEL SERVICE GROUP
PL_SG_pkg=(httpd)
for (( x=0; x<${#PL_SG_pkg[@]}; x++ )); do
    litp create -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}" -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs$(($x+1)) node_list='n1,n2' offline_timeout=10 online_timeout=10
    litp create -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/ha_configs/conf1 -t ha-service-config -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2
    litp create -p /software/items/"${PL_SG_pkg[$x]}" -t package -o name="${PL_SG_pkg[$x]}" 
    litp create -p /software/services/"${PL_SG_pkg[$x]}" -t service -o service_name="${PL_SG_pkg[$x]}"
    litp inherit -p /software/services/"${PL_SG_pkg[$x]}"/packages/pkg1 -s /software/items/"${PL_SG_pkg[$x]}"
    litp inherit -p /deployments/d1/clusters/c1/services/"${PL_SG_pkg[$x]}"/applications/"${PL_SG_pkg[$x]}" -s /software/services/"${PL_SG_pkg[$x]}"
done

###############################################################
# CREATE PLAN
###############################################################

litp create_plan
