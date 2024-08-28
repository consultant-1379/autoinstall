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

# 0 or 1 depending on whether expanding to 3 or 4 respectively
expansion_index=1

litpcrypt set key-for-root root "${nodes_ilo_password}"
litpcrypt set key-for-sfs "${sfs_username}" "${sfs_password}"

# DISK CREATION FOR SYSTEMS - PEER NODES
litp create -p /infrastructure/systems/sys$(($expansion_index+4)) -t blade -o system_name="${node_expansion_sysname[$expansion_index]}"
# DISK SETUP
litp create -p /infrastructure/systems/sys$(($expansion_index+4))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_expansion_disk_uuid[$expansion_index]}"
litp create -p /infrastructure/systems/sys$(($expansion_index+4))/disks/disk1 -t disk -o name=hd1 size=9G bootable=false uuid="${node_expansion_disk1_uuid[$expansion_index]}"
# BMC SETUP FOR PXE BOOTING BLADES
litp create -p /infrastructure/systems/sys$(($expansion_index+4))/bmc -t bmc -o ipaddress="${node_expansion_bmc_ip[$expansion_index]}" username=root password_key=key-for-root

##### STORAGE SETUP #####

############################################################################
# CLUSTERING SETUP
############################################################################

#Create VXVM discs for node4 in the same cluster as existing vxvm
litp create -p /infrastructure/systems/sys5/disks/disk2 -t disk -o name=hd2 size=10G bootable=false uuid="${node_vxvm_uuid[0]}"
litp create -p /infrastructure/systems/sys5/disks/disk3 -t disk -o name=hd3 size=400M bootable=false uuid="${node_vxvm2_uuid[0]}"

# INDIVIDUAL NODE SETUP

# HOSTNAME SETUP
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3)) -t node -o hostname="${node_expansion_hostname[$expansion_index]}"

# INHERIT SYSTEM SETUP FROM ABOVE
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/system -s  /infrastructure/systems/sys$(($expansion_index+4))

# CREATE OS PROFILE
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/os -s /software/profiles/os_prof1

# CREATE STORAGE PROFILE
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1

# HA YUM REPOSITORY
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/items/yum_osHA_repo -s /software/items/yum_osHA_repo

# INHERIT SPECIFIC SOFTWARE ITEMS
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/items/ntp1 -s /software/items/ntp1
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/items/java -s /software/items/openjdk
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/items/dovecot -s /software/items/dovecot

# LOG ROTATE RULES FOR THE NODE
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/logrotate -t logrotate-rule-config
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

##### NETWORK SETUP FOR EACH NIC #####

# GATEWAY SETUP FOR NODE
litp create -p /infrastructure/networking/routes/traffic3_gw_n$(($expansion_index+3)) -t route -o subnet=${traffic_network3_gw_subnet} gateway="${node_expansion_ip_4[$expansion_index]}"

# BRIDGE ETH0
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_expansion_eth0_mac[$expansion_index]}" bridge='br0'
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_expansion_ip[$expansion_index]}" ipv6address="${node_expansion_ipv6_00[$expansion_index]}" network_name='mgmt' stp=true
# HEARTBEAT NETWORK SETUP
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_expansion_eth2_mac[$expansion_index]}" network_name=hb1
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_expansion_eth3_mac[$expansion_index]}" network_name=hb2
# TRAFFIC NETWORKS
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_expansion_eth4_mac[$expansion_index]}" network_name='traffic1' ipaddress="${node_expansion_ip_2[$expansion_index]}"
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_expansion_eth5_mac[$expansion_index]}" network_name='traffic2' ipaddress="${node_expansion_ip_3[$expansion_index]}"
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if6 -t eth -o device_name=eth6 macaddress="${node_expansion_eth6_mac[$expansion_index]}" network_name='traffic3' ipaddress="${node_expansion_ip_4[$expansion_index]}"

# ROUTE SETUP
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/routes/r1 -s /infrastructure/networking/routes/r1
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

# GATEWAY SETUP FOR NODES
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n$(($expansion_index+3))

# CREATE FIREWALL SETUP FOR NODES
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init -t firewall-node-config
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o name='099 icmpipv6' proto=ipv6-icmp provider=ip6tables
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

# NFS MOUNTS
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2

# SYSCTRL PARAMS FOR NODES
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/init_config -t sysparam-node-config
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/init_config/params/sysctrl_01 -t sysparam -o key="net.ipv4.tcp_wmem" value="4096 65536 16777215"

# DNS SETUP FOR NODES
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.4 position=1

# NODE SERVICES
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/services/sentinel -s /software/services/sentinel

FO_SG_pkg1=mysgroup4
PL_SG_pkg1=mysgroup5
SL_SG_pkg1=mysgroup6
FO_SG_pkg2=mysgroup7
PL_SG_pkg3=mysgroup8
SL_SG_pkg3=mysgroup9

litp create -p /deployments/d1/clusters/c1/network_hosts/nh20 -t vcs-network-host -o network_name="traffic1" ip="${node_expansion_ip_2[1]}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh22 -t vcs-network-host -o network_name="traffic2" ip="${node_expansion_ip_3[1]}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh24 -t vcs-network-host -o network_name="traffic3" ip="${node_expansion_ip_4[1]}"

litp import /tmp/test_services/test_service-1.0-1.noarch.rpm 3pp

# FAILOVER SERVICE GROUP

litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1" -t vcs-clustered-service -o active=1 standby=1 name=FO_vcs2 online_timeout=45 node_list='n4,n3'
litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1"/ha_configs/conf1 -t ha-service-config -o status_interval=50 status_timeout=50 restart_limit=10 startup_retry_limit=3 service_id=cups dependency_list=ricci
litp inherit -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1"/applications/cups -s /software/services/cups
litp create -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1"/ha_configs/conf2 -t ha-service-config -o status_interval=70 status_timeout=70 restart_limit=12 startup_retry_limit=3 service_id=ricci
litp inherit -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1"/applications/ricci -s /software/services/ricci
litp create  -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_fo2_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg1"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_fo2_vip2}" network_name=traffic3

# PARALLEL SERVICE GROUP

litp create -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg1" -t vcs-clustered-service -o active=2 standby=0 name=PL_vcs2 node_list='n3,n4' dependency_list=$FO_SG_pkg1
litp create -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg1"/ha_configs/conf1 -t ha-service-config -o status_interval=80 status_timeout=60 restart_limit=5 startup_retry_limit=2
litp create -p /software/items/test_service -t package -o name=test_service
litp create -p /software/services/test_service -t service -o service_name="test_service.sh"
litp inherit -p /software/services/test_service/packages/pkg1 -s /software/items/test_service
litp inherit -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg1"/applications/test_service -s /software/services/test_service
litp create  -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg1"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_pl2_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg1"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_pl2_vip2}" network_name=traffic3

# PARALLEL SERVICE GROUP

litp create -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1" -t vcs-clustered-service -o active=1 standby=0 name=SL_vcs2 node_list='n4'
litp create -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/ha_configs/conf1 -t ha-service-config -o status_interval=100 status_timeout=60 restart_limit=6 startup_retry_limit=3
litp inherit -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/applications/luci -s /software/services/luci
litp create  -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_sl2_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_sl2_vip1_ipv6}" network_name=traffic3

########## VCS SERVICE GROUPS - CLUSTER SERVICES #############
# PEER NODE NETWORK

litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/if7 -t eth -o device_name=eth7 macaddress="${node_expansion_eth7_mac[$expansion_index]}"
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/br7 -t bridge -o device_name=br7 network_name=net1vm ipaddress="${net1vm_ip[$expansion_index+2]}"
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/network_interfaces/vlan911 -t vlan -o device_name=eth7.911 bridge=br7

# FIREWALL FOR NODES
litp create -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/configs/fw_config_init/rules/fw_vmhc -t firewall-rule -o name="300 vmhc" proto="tcp" dport=12987 provider=iptables


# CREATE THE FAILOVER SERVICE GROUP
litp create -p /software/images/image4 -t vm-image -o name="FO_SG_vm2" source_uri="http://${ms_ip}/images/image_with_ocf_v1_8.qcow2"
litp create -p /software/services/vmservice4 -t vm-service -o service_name="CIvmserv4" image_name="FO_SG_vm2" cpus=2 ram=4500M internal_status_check=on cleanup_command="/sbin/service CIvmserv4 force-stop"
litp create -p /deployments/d1/clusters/c1/services/FO_SG_vm2 -t vcs-clustered-service -o name="FO_SG_vm2" active=1 standby=1 node_list='n1,n4' online_timeout=500 dependency_list='PL_SG_vm2'
litp inherit -p /deployments/d1/clusters/c1/services/FO_SG_vm2/applications/vmservice4 -s /software/services/vmservice4
litp create -p /software/services/vmservice4/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br7 network_name=net1vm
litp update -p /deployments/d1/clusters/c1/services/FO_SG_vm2/applications/vmservice4/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[5]}" gateway=${net1vm_gateway}
litp create -p /software/services/vmservice4/vm_aliases/cims -t vm-alias -o alias_names=cims address=${net1vm_ip_ms}
litp create -p /software/services/vmservice4/vm_aliases/cinode1 -t vm-alias -o alias_names=cinode1 address=${net1vm_ip[0]}
litp create -p /software/services/vmservice4/vm_aliases/cinode4 -t vm-alias -o alias_names=cinode4 address=${net1vm_ip[3]}
litp create -p /software/services/vmservice4/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_ip}/6/os/x86_64"
litp create -p /software/services/vmservice4/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages" # UPDATE
litp create -p /software/services/vmservice4/vm_packages/wireshark -t vm-package -o name=wireshark
litp create -p /software/services/vmservice4/vm_ssh_keys/sshkey1 -t vm-ssh-key -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+bE5= key2@localhost.localdomain'

###############################################################
# UPDATE FROM INSTALL WITH EXPANSION
###############################################################

FO_SG_pkg=mysgroup1
PL_SG_pkg=mysgroup2
SL_SG_pkg=mysgroup3
RM_SG_pkg=mysgroup10

# UPDATE EXISTING SG's

# UPDATE SGs from previous expansion

# Update vm services from previous expansion
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm2 -o active=2 node_list='n3,n4'
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm2/applications/vmservice3/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[3]},${vm_ip[4]}"
litp create -p /software/services/vmservice3/vm_aliases/cinode4 -t vm-alias -o alias_names=cinode4 address=${net1vm_ip[3]}

litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm5 -o active=4 node_list='n3,n2,n1,n4'
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm5/applications/vmservice7/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[11]},${vm_ip[12]},${vm_ip[13]},${vm_ip[14]}"
litp create -p /software/services/vmservice7/vm_aliases/cinode4 -t vm-alias -o alias_names=cinode4 address=${net1vm_ip[3]}

# CREATE MANAGED SHARES ON SFS
litp update -p /infrastructure/storage/storage_providers/sfs_service_sp1/pools/sfs_pool1/file_systems/managed_fs2/exports/export2 -o ipv4allowed_clients="${node_ip[0]},${node_ip[1]},${node_expansion_ip[0]},${node_expansion_ip[1]}"

# MANAGED SFS MOUNTS
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/file_systems/mfs1 -s /infrastructure/storage/nfs_mounts/mount2
litp inherit -p /deployments/d1/clusters/c1/nodes/n$(($expansion_index+3))/file_systems/mfs2 -s /infrastructure/storage/nfs_mounts/mount3

#UPDATE NODE_LIST AS PER TORF-159091
litp update -p /deployments/d1/clusters/c1/services/mysgroup2 -o active=3 node_list=n3,n4,n2

###############################################################
# CREATE PLAN
###############################################################

litp create_plan
