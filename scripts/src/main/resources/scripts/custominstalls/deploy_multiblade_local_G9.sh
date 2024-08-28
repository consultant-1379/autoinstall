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
#


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
litp create  -p /software/services/sentinel -t service -o service_name=sentinel
litp inherit -p /software/services/sentinel/packages/sentinel -s /software/items/sentinel

############################################################################
# DEPLOYMENTS
############################################################################

litp create -p /deployments/d1 -t deployment

############################################################################
# INFRASTRUCTURE
############################################################################

##Create storage 1
litp create -p /ms/services/cobbler -t cobbler-service
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=16G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0


# CREATE BLADE FOR SYSTEM 1 - MS
litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=40G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

##### NETWORKING SETUP #####

# ROUTES IPV4
litp create -p /infrastructure/networking/routes/r1 -t route -o subnet="0.0.0.0/0" gateway="${nodes_gateway}"

# ROUTES IPV6
litp create -p /infrastructure/networking/routes/default_ipv6 -t route6 -o subnet=::/0 gateway="${ipv6_gateway}"

# NEW GATEWAY FOR TRAFFIC NETWORK
#litp create -p /infrastructure/networking/routes/traffic2_gw -t route -o subnet=${traffic_network2_gw_subnet} gateway=${traffic_network2_gw}

# SETUP MGMT NETWORK
litp create -p /infrastructure/networking/networks/mgmt -t network -o name=mgmt subnet="${nodes_subnet}" litp_management=true

# HEARTBEAT NETWORKS FOR VCS
litp create -p /infrastructure/networking/networks/heartbeat1 -t network -o name=hb1
#litp create -p /infrastructure/networking/networks/heartbeat2 -t network -o name=hb2

# TRAFFIC NETWORKS FOR VCS
#litp create -p /infrastructure/networking/networks/traffic1 -t network -o name='traffic1' subnet="${traffic_network1_subnet}"
#litp create -p /infrastructure/networking/networks/traffic2 -t network -o name='traffic2' subnet="${traffic_network2_subnet}"
#litp create -p /infrastructure/networking/networks/traffic3 -t network -o name='traffic3' subnet="${traffic_network3_subnet}"

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
litp create -p /ms/network_interfaces/b0 -t bond -o device_name=bondmgmt ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt

# SETUP A BRIDGE ON THE MGMT NETWORK
#litp create -p /ms/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${ms_ip}" ipv6address="${ms_ipv6_00}" network_name=mgmt stp=true

# VLAN ON THE BRIDGE
#litp create -p /ms/network_interfaces/b0_vlan -t vlan -o device_name=bondmgmt.${ms_vlan_id} bridge=br0 

# SETUP ALIAS ON MS USING NTP AS AN EXAMPLE
litp create -p /ms/configs/alias_config -t alias-node-config
litp create -p /ms/configs/alias_config/aliases/ntp_alias1 -t alias -o alias_names="ntpAlias1" address="${ntp_ip[1]}"

# FIREWALL SETUP FOR  MS
litp create -p /ms/configs/fw_config_init -t firewall-node-config
litp create -p /ms/configs/fw_config_init/rules/fw_icmp -t firewall-rule -o name="100 icmp" proto="icmp"
litp create -p /ms/configs/fw_config_init/rules/fw_icmpv6 -t firewall-rule -o name="099 icmpv6" proto="ipv6-icmp" provider=ip6tables
litp create -p /ms/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /ms/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp

# SYSCTRL PARAMS FOR MS
litp create -p /ms/configs/mynodesysctl -t sysparam-node-config
litp create -p /ms/configs/mynodesysctl/params/sysctl_MS01 -t sysparam -o key=net.ipv4.udp_mem value="24794401 33059201 49588801"

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
litp create -p /deployments/d1/clusters/c1 -t vcs-cluster -o cluster_type=sfha low_prio_net=mgmt llt_nets='hb1' cluster_id="${cluster_id}" default_nic_monitor="mii"

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

    # BRIDGE ETH0
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_eth0_mac[$i]}" bridge='br0'
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_ip[$i]}" ipv6address="${node_ipv6_00[$i]}" network_name='mgmt' stp=true
    # HEARTBEAT NETWORK SETUP
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if2 -t eth -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" network_name=hb1
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_eth3_mac[$i]}" network_name=hb2

    # TRAFFIC NETWORKS
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_eth4_mac[$i]}" network_name='traffic1' ipaddress="${node_ip_2[$i]}"
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_eth5_mac[$i]}" network_name='traffic2' ipaddress="${node_ip_3[$i]}" 
    #litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if1 -t eth -o device_name=eth1 macaddress="${node_eth1_mac[$i]}" network_name='traffic3' ipaddress="${node_ip_4[$i]}"

    # ROUTE SETUP
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r1 -s /infrastructure/networking/routes/r1
    litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

    # GATEWAY SETUP FOR NODES
    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
    #litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n$(($i+1))

    # CREATE FIREWALL SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init -t firewall-node-config 
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o 'name=011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o 'name=001 nfstcp' dport=111,2049,4001 proto=tcp
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o 'name=099 icmpipv6' proto=ipv6-icmp

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

# CLUSTER NETWORK SETUP
litp create -p /deployments/d1/clusters/c1/network_hosts/nh1 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host1}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh2 -t vcs-network-host -o network_name="mgmt"     ip="${ms_ip}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh3 -t vcs-network-host -o network_name="mgmt"     ip="${vcs_network_host3}" 
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh4 -t vcs-network-host -o network_name="traffic1" ip="${ms_ip}"
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh5 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host5}"
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh6 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host6}" 
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh7 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host7}" 
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh8 -t vcs-network-host -o network_name="traffic2" ip="${vcs_network_host8}" 
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh9 -t vcs-network-host -o network_name="traffic2" ip="${ms_ipv6_00_noprefix}"
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh10 -t vcs-network-host -o network_name="traffic2" ip="${vcs_network_host10}"
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh11 -t vcs-network-host -o network_name="traffic1" ip="${vcs_network_host11}"
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh12 -t vcs-network-host -o network_name=traffic1 ip=${traffic_network1_gw}
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh13 -t vcs-network-host -o network_name=traffic1 ip="${node_ip_2[1]}" #NOTE HARDCODED TO 2nd NODE IP
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh14 -t vcs-network-host -o network_name=traffic2 ip=${traffic_network2_gw}
#litp create -p /deployments/d1/clusters/c1/network_hosts/nh15 -t vcs-network-host -o network_name=traffic2 ip="${node_ip_3[1]}" #NOTE HARDCODED TO 2nd NODE IP


########## VCS SERVICE GROUPS - CLUSTER SERVICES #############

# FAILOVER SERVICE GROUP
#FO_SG_pkg=cups

#litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg" -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs1 online_timeout=45 node_list='n2,n1' dependency_list=httpd
#litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/ha_configs/conf1 -t ha-service-config -o status_interval=30 status_timeout=30 restart_limit=10 startup_retry_limit=3
#litp create -p /software/items/"$FO_SG_pkg" -t package -o name="$FO_SG_pkg"
#litp create -p /software/services/"$FO_SG_pkg" -t service -o service_name="$FO_SG_pkg"
#litp inherit -p /software/services/"$FO_SG_pkg"/packages/pkg1 -s /software/items/"$FO_SG_pkg"
#litp inherit -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/applications/"$FO_SG_pkg" -s /software/services/"$FO_SG_pkg"
#litp create  -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_pl1_vip1}" network_name=traffic3
#litp create  -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_pl1_vip2}" network_name=traffic3
#litp inherit -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg"/filesystems/fs1 -s /deployments/d1/clusters/c1/storage_profile/vxvm_profile/volume_groups/vg1_vxvm/file_systems/data1_vxvm

# PARALLEL SERVICE GROUP
#PL_SG_pkg=httpd

#litp create -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg" -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs node_list='n1,n2'
#litp create -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/ha_configs/conf1 -t ha-service-config -o status_interval=10 status_timeout=10 restart_limit=5 startup_retry_limit=2
#litp create -p /software/items/"$PL_SG_pkg" -t package -o name="$PL_SG_pkg" epoch=0
#litp create -p /software/services/"$PL_SG_pkg" -t service -o service_name="$PL_SG_pkg"
#litp inherit -p /software/services/"$PL_SG_pkg"/packages/pkg1 -s /software/items/"$PL_SG_pkg"
#litp inherit -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/applications/"$PL_SG_pkg" -s /software/services/"$PL_SG_pkg"
#litp create  -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_fo1_vip1}" network_name=traffic3
#litp create  -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_fo1_vip2}" network_name=traffic3


### VM NETWORK SETUP
# INFRASTRUCTURE
#litp create -p /infrastructure/networking/networks/net1vm -t network -o name=net1vm subnet="${net1vm_subnet}"

# MS BRIDGING
#litp create -p /ms/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${ms_eth2_mac}"
#litp create -p /ms/network_interfaces/br2 -t bridge -o device_name=br2 network_name=net1vm ipaddress="${net1vm_ip_ms}"
#litp create -p /ms/network_interfaces/vlan911 -t vlan -o device_name=eth2.911 bridge=br2

# PEER NODE NETWORK

#for (( i=0; i<${#node_sysname[@]}; i++ )); do
#    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/if7 -t eth -o device_name=eth7 macaddress="${node_eth7_mac[$i]}"
#    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/br7 -t bridge -o device_name=br7 network_name=net1vm ipaddress="${net1vm_ip[$i]}"
#    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_interfaces/vlan911 -t vlan -o device_name=eth7.911 bridge=br7

    # FIREWALL FOR NODES
#    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/configs/fw_config_init/rules/fw_vmhc -t firewall-rule -o name="300 vmhc" proto="tcp" dport=12987 provider=iptables
#done
# SETUP THE VM_IMAGE
#/usr/bin/md5sum /var/www/html/images/image_with_ocf_v1_7.qcow2 | cut -d ' ' -f 1 | tee /var/www/html/images/image_with_ocf_v1_7.qcow2.md5 2>&1
#retval=( $(echo "$?") )
#if [ $retval -ne 0 ]
#then
#    exit 1
#fi

# CREATE THE PARALLEL SERVICE GROUP
#litp create -p /software/images/image1 -t vm-image -o name="PL_SG_vm1" source_uri="http://${ms_ip}/images/image_with_ocf_v1_7.qcow2"
#litp create -p /software/services/vmservice1 -t vm-service -o service_name="CIvmserv1" image_name="PL_SG_vm1" cpus=4 ram=2000M internal_status_check=on cleanup_command="/sbin/service CIvmserv1 force-stop"
#litp create -p /deployments/d1/clusters/c1/services/PL_SG_vm1 -t vcs-clustered-service -o name="PL_SG_vm1" active=2 standby=0 node_list='n1,n2' online_timeout=400
#litp inherit -p /deployments/d1/clusters/c1/services/PL_SG_vm1/applications/vmservice1 -s /software/services/vmservice1
#litp create -p /software/services/vmservice1/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br7 network_name=net1vm
#litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm1/applications/vmservice1/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[0]},${vm_ip[1]}" gateway=${net1vm_gateway}
#litp create -p /software/services/vmservice1/vm_aliases/cims -t vm-alias -o alias_names=cims address=${net1vm_ip_ms}
#litp create -p /software/services/vmservice1/vm_aliases/cinode1 -t vm-alias -o alias_names=cinode1 address=${net1vm_ip[0]}
#litp create -p /software/services/vmservice1/vm_aliases/cinode2 -t vm-alias -o alias_names=cinode2 address=${net1vm_ip[1]}
#litp create -p /software/services/vmservice1/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_ip}/6/os/x86_64"
#litp create -p /software/services/vmservice1/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages" # UPDATE
#litp create -p /software/services/vmservice1/vm_packages/cups -t vm-package -o name=cups

# CREATE THE FAILOVER SERVICE GROUP
#litp create -p /software/images/image2 -t vm-image -o name="FO_SG_vm1" source_uri="http://${ms_ip}/images/image_with_ocf_v1_7.qcow2"
#litp create -p /software/services/vmservice2 -t vm-service -o service_name="CIvmserv2" image_name="FO_SG_vm1" cpus=2 ram=4000M internal_status_check=on cleanup_command="/sbin/service CIvmserv2 force-stop"
#litp create -p /deployments/d1/clusters/c1/services/FO_SG_vm1 -t vcs-clustered-service -o name="FO_SG_vm1" active=1 standby=1 node_list='n1,n2' online_timeout=300
#litp inherit -p /deployments/d1/clusters/c1/services/FO_SG_vm1/applications/vmservice2 -s /software/services/vmservice2
#litp create -p /software/services/vmservice2/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br7 network_name=net1vm
#litp update -p /deployments/d1/clusters/c1/services/FO_SG_vm1/applications/vmservice2/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[2]}" gateway=${net1vm_gateway}
#litp create -p /software/services/vmservice2/vm_aliases/cims -t vm-alias -o alias_names=cims address=${net1vm_ip_ms}
#litp create -p /software/services/vmservice2/vm_aliases/cinode1 -t vm-alias -o alias_names=cinode1 address=${net1vm_ip[0]}
#litp create -p /software/services/vmservice2/vm_aliases/cinode2 -t vm-alias -o alias_names=cinode2 address=${net1vm_ip[1]}
#litp create -p /software/services/vmservice2/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_ip}/6/os/x86_64"
#litp create -p /software/services/vmservice2/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages" # UPDATE
#litp create -p /software/services/vmservice2/vm_packages/cups -t vm-package -o name=wireshark

###############################################################
# CREATE PLAN
###############################################################

litp create_plan
