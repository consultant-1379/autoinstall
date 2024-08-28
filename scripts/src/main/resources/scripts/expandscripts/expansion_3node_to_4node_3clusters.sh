#!/bin/bash
#
# Expansion from "3 nodes in 1 cluster" to "3 nodes in first cluster and 1 node in second cluster"
#
# Usage:
#   expansion_3node_to_4node_2clusters.sh <CLUSTER_SPEC_FILE>
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
litpcrypt set key-for-sfs "${sfs_username}" "${sfs_password}"

# DISK CREATION FOR SYSTEMS - PEER NODES
litp create -p /infrastructure/systems/sys5 -t blade -o system_name="${node_expansion_sysname[1]}"
# DISK SETUP
litp create -p /infrastructure/systems/sys5/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_expansion_disk_uuid[1]}"
litp create -p /infrastructure/systems/sys5/disks/disk1 -t disk -o name=hd1 size=9G bootable=false uuid="${node_expansion_disk1_uuid[1]}"
# BMC SETUP FOR PXE BOOTING BLADES
litp create -p /infrastructure/systems/sys5/bmc -t bmc -o ipaddress="${node_expansion_bmc_ip[1]}" username=root password_key=key-for-root

############################################################################
# CLUSTERING SETUP
############################################################################

# CLUSTER CREATION - VCS
litp create -p /deployments/d1/clusters/c3 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets='hb1,hb2' cluster_id="${cluster3_id}" default_nic_monitor="mii"

# CLUSTER CONFIGURATION FOR FILEWALLS
litp create -p /deployments/d1/clusters/c3/configs/fw_config_init -t firewall-cluster-config
litp create -p /deployments/d1/clusters/c3/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"

# CLUSTER 3 NETWORK SETUP
litp create -p /deployments/d1/clusters/c3/network_hosts/nh1 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host26}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh2 -t vcs-network-host -o network_name="mgmt"     ip="${ms_ip}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh3 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host27}" 
litp create -p /deployments/d1/clusters/c3/network_hosts/nh4 -t vcs-network-host -o network_name="traffic1" ip="${ms_ip}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh5 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host28}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh6 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host29}" 
litp create -p /deployments/d1/clusters/c3/network_hosts/nh7 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host30}" 
litp create -p /deployments/d1/clusters/c3/network_hosts/nh8 -t vcs-network-host -o network_name="traffic2" ip="${vcs_network_host31}" 
litp create -p /deployments/d1/clusters/c3/network_hosts/nh9 -t vcs-network-host -o network_name="traffic2" ip="${ms_ipv6_00_noprefix}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh10 -t vcs-network-host -o network_name="traffic2" ip="${vcs_network_host32}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh11 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host33}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh12 -t vcs-network-host -o network_name="traffic1" ip="${node_expansion_ip_2[1]}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh13 -t vcs-network-host -o network_name="traffic2" ip="${node_expansion_ip_3[1]}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh16 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host34}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh17 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host35}"
litp create -p /deployments/d1/clusters/c3/network_hosts/nh18 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host36}"

# INDIVIDUAL NODE SETUP

# HOSTNAME SETUP
litp create -p /deployments/d1/clusters/c3/nodes/n4 -t node -o hostname="${node_expansion_hostname[1]}"

# INHERIT SYSTEM SETUP FROM ABOVE
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/system -s  /infrastructure/systems/sys5

# CREATE OS PROFILE
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/os -s /software/profiles/os_prof1

# CREATE STORAGE PROFILE
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 

# HA YUM REPOSITORY
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/items/yum_osHA_repo -s /software/items/yum_osHA_repo

# INHERIT SPECIFIC SOFTWARE ITEMS
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/items/java -s /software/items/openjdk
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/items/dovecot -s /software/items/dovecot

# LOG ROTATE RULES FOR THE NODE
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/logrotate -t logrotate-rule-config
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

##### NETWORK SETUP FOR EACH NIC #####

# GATEWAY SETUP FOR NODE
litp create -p /infrastructure/networking/routes/traffic3_gw_n4 -t route -o subnet=${traffic_network3_gw_subnet} gateway="${node_expansion_ip_4[1]}"

# BRIDGE ETH0
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_expansion_eth0_mac[1]}" bridge='br0'
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_expansion_ip[1]}" ipv6address="${node_expansion_ipv6_00[1]}" network_name='mgmt' stp=true
# HEARTBEAT NETWORK SETUP
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_expansion_eth2_mac[1]}" network_name=hb1
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_expansion_eth3_mac[1]}" network_name=hb2
# TRAFFIC NETWORKS
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_expansion_eth4_mac[1]}" network_name='traffic1' ipaddress="${node_expansion_ip_2[1]}"
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_expansion_eth5_mac[1]}" network_name='traffic2' ipaddress="${node_expansion_ip_3[1]}" 
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_expansion_eth6_mac[1]}" network_name='traffic3' ipaddress="${node_expansion_ip_4[1]}"

# ROUTE SETUP
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

# GATEWAY SETUP FOR NODES
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n4

# CREATE FIREWALL SETUP FOR NODES
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init -t firewall-node-config 
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o name='099 icmpipv6' proto=ipv6-icmp provider=ip6tables
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

# NFS MOUNTS
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2

# SYSCTRL PARAMS FOR NODES
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/init_config -t sysparam-node-config
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/init_config/params/sysctrl_01 -t sysparam -o key="net.ipv4.tcp_wmem" value="4096 65536 16777215"

# DNS SETUP FOR NODES
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.4 position=1

# NODE SERVICES
litp inherit -p /deployments/d1/clusters/c3/nodes/n4/services/sentinel -s /software/services/sentinel

########## VCS SERVICE GROUPS - CLUSTER 2 SERVICE #############

SL_SG_pkg2=mysgroup5
# SL SERVICE GROUP
litp create -p /deployments/d1/clusters/c3/services/"$SL_SG_pkg2" -t vcs-clustered-service -o active=1 standby=0 name=SL_vcs2 node_list='n4'
litp create -p /deployments/d1/clusters/c3/services/"$SL_SG_pkg2"/ha_configs/conf1 -t ha-service-config -o status_interval=100 status_timeout=60 restart_limit=6 startup_retry_limit=3
litp inherit -p /deployments/d1/clusters/c3/services/"$SL_SG_pkg2"/applications/luci -s /software/services/luci
litp create  -p /deployments/d1/clusters/c3/services/"$SL_SG_pkg2"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_sl3_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c3/services/"$SL_SG_pkg2"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_sl3_vip1_ipv6}" network_name=traffic3

# PEER NODE NETWORK
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/if7 -t eth -o device_name=eth7 macaddress="${node_expansion_eth7_mac[1]}"
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/br7 -t bridge -o device_name=br7 network_name=net1vm ipaddress="${net1vm_ip[3]}"
litp create -p /deployments/d1/clusters/c3/nodes/n4/network_interfaces/vlan911 -t vlan -o device_name=eth7.911 bridge=br7

# FIREWALL FOR NODES
litp create -p /deployments/d1/clusters/c3/nodes/n4/configs/fw_config_init/rules/fw_vmhc -t firewall-rule -o name="300 vmhc" proto="tcp" dport=12987 provider=iptables

###############################################################
# CREATE PLAN
###############################################################

litp create_plan
