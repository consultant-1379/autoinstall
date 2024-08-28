#!/bin/bash
#
# Expansion from "2 nodes in 1 cluster" to "4 nodes in 1 cluster"
#
# Usage:
#   expansion_2node_to_4node_1cluster_vxvm.sh <CLUSTER_SPEC_FILE>
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

for (( i=0; i<${#node_expansion_sysname[@]}; i++ )); do
    # DISK CREATION FOR SYSTEMS - PEER NODES
    litp create -p /infrastructure/systems/sys$(($i+4)) -t blade -o system_name="${node_expansion_sysname[$i]}"
    # DISK SETUP
    litp create -p /infrastructure/systems/sys$(($i+4))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_expansion_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+4))/disks/disk1 -t disk -o name=hd1 size=9G bootable=false uuid="${node_expansion_disk1_uuid[$i]}"
    # BMC SETUP FOR PXE BOOTING BLADES
    litp create -p /infrastructure/systems/sys$(($i+4))/bmc -t bmc -o ipaddress="${node_expansion_bmc_ip[$i]}" username=root password_key=key-for-root
done

#Create VXVM discs for node3 in the same cluster as existing vxvm
litp create -p /infrastructure/systems/sys4/disks/disk2 -t disk -o name=hd2 size=10G bootable=false uuid="${node_vxvm_uuid[0]}"
litp create -p /infrastructure/systems/sys4/disks/disk3 -t disk -o name=hd3 size=400M bootable=false uuid="${node_vxvm2_uuid[0]}"

#Create VXVM discs for node4 in the same cluster as existing vxvm
litp create -p /infrastructure/systems/sys5/disks/disk2 -t disk -o name=hd2 size=10G bootable=false uuid="${node_vxvm_uuid[0]}"
litp create -p /infrastructure/systems/sys5/disks/disk3 -t disk -o name=hd3 size=400M bootable=false uuid="${node_vxvm2_uuid[0]}"

############################################################################
# CLUSTERING SETUP
############################################################################

# CLUSTER 1 NETWORK ADD

litp create -p /deployments/d1/clusters/c1/network_hosts/nh19 -t vcs-network-host -o network_name=traffic1 ip="${node_expansion_ip_2[0]}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh20 -t vcs-network-host -o network_name=traffic2 ip="${node_expansion_ip_3[0]}"
litp create -p /deployments/d1/clusters/c1/network_hosts/nh21 -t vcs-network-host -o network_name=traffic3 ip="${node_expansion_ip_4[0]}"

# ALIAS CLUSTER CONFIG FOR TORF-146545
litp remove -p /deployments/d1/clusters/c1/configs/alias_config/aliases/alias_mn1
litp create -p /deployments/d1/clusters/c1/configs/alias_config/aliases/alias_mn3 -t alias -o alias_names='svc-3-map-service,map-service-1-internal' address="${ntp_ip[3]}"

# INDIVIDUAL NODE SETUP
cluster=1
for (( i=0; i<${#node_expansion_sysname[@]}; i++ )); do

    # HOSTNAME SETUP
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3)) -t node -o hostname="${node_expansion_hostname[$i]}"

    # INHERIT SYSTEM SETUP FROM ABOVE
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/system -s  /infrastructure/systems/sys$(($i+4))

    # CREATE OS PROFILE
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/os -s /software/profiles/os_prof1

    # CREATE STORAGE PROFILE
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/storage_profile -s /infrastructure/storage/storage_profiles/profile_1 
    
    # HA YUM REPOSITORY
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/items/yum_osHA_repo -s /software/items/yum_osHA_repo

    # INHERIT SPECIFIC SOFTWARE ITEMS
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/items/ntp1 -s /software/items/ntp1
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/items/java -s /software/items/openjdk
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/items/dovecot -s /software/items/dovecot

    # LOG ROTATE RULES FOR THE NODE
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/logrotate -t logrotate-rule-config
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/logrotate/rules/messages -t logrotate-rule -o name="syslog" path="/var/log/messages,/var/log/cron,/var/log/maillog,/var/log/secure,/var/log/spooler" size=10M rotate=50 copytruncate=true sharedscripts=true postrotate="/bin/kill -HUP \`cat /var/run/syslogd.pid 2> /dev/null\` 2> /dev/null || true"

    ##### NETWORK SETUP FOR EACH NIC #####

    # GATEWAY SETUP FOR NODE
    litp create -p /infrastructure/networking/routes/traffic3_gw_n$(($i+3)) -t route -o subnet=${traffic_network3_gw_subnet} gateway="${node_expansion_ip_4[$i]}"

    # BRIDGE ETH0
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/if0 -t eth -o device_name=eth0 macaddress="${node_expansion_eth0_mac[$i]}" bridge='br0'
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/br0 -t bridge -o device_name=br0 ipaddress="${node_expansion_ip[$i]}" ipv6address="${node_expansion_ipv6_00[$i]}" network_name='mgmt' stp=true
    # HEARTBEAT NETWORK SETUP
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/if2 -t eth -o device_name=eth2 macaddress="${node_expansion_eth2_mac[$i]}" network_name=hb1
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/if3 -t eth -o device_name=eth3 macaddress="${node_expansion_eth3_mac[$i]}" network_name=hb2
    # TRAFFIC NETWORKS
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/if4 -t eth -o device_name=eth4 macaddress="${node_expansion_eth4_mac[$i]}" network_name='traffic2' ipaddress="${node_expansion_ip_3[$i]}"
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/if5 -t eth -o device_name=eth5 macaddress="${node_expansion_eth5_mac[$i]}" network_name='traffic3' ipaddress="${node_expansion_ip_4[$i]}"
    
    # ROUTE SETUP
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/routes/r1 -s /infrastructure/networking/routes/r1
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/routes/r2_ipv6 -s /infrastructure/networking/routes/default_ipv6

    # GATEWAY SETUP FOR NODES
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/routes/traffic2_gw -s /infrastructure/networking/routes/traffic2_gw
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/routes/traffic3_gw -s /infrastructure/networking/routes/traffic3_gw_n$(($i+3))

    # CREATE FIREWALL SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init -t firewall-node-config 
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init/rules/fw_nfsudp -t firewall-rule -o name='011 nfsudp' dport=111,2049,4001 proto=udp
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init/rules/fw_nfstcp -t firewall-rule -o name='001 nfstcp' dport=111,2049,4001 proto=tcp
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init/rules/fw_icmp_ip6 -t firewall-rule -o name='099 icmpipv6' proto=ipv6-icmp provider=ip6tables
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init/rules/fw_dnstcp -t firewall-rule -o name='200 dnstcp' dport=53 proto=tcp
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init/rules/fw_dnsudp -t firewall-rule -o name='201 dnsudp' dport=53 proto=udp

    # NFS MOUNTS
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/file_systems/nm1 -s /infrastructure/storage/nfs_mounts/nm1
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/file_systems/nm2 -s /infrastructure/storage/nfs_mounts/nm2

    # SYSCTRL PARAMS FOR NODES
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/init_config -t sysparam-node-config
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/init_config/params/sysctrl_01 -t sysparam -o key="net.ipv4.tcp_wmem" value="4096 65536 16777215"
	
    # DNS SETUP FOR NODES
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/dns_client -t dns-client -o search=ammeonvpn.com,exampleone.com,exampletwo.com,examplethree.com,examplefour.com,examplefive.com
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/dns_client/nameservers/init_name_server -t nameserver -o ipaddress=10.44.86.4 position=1

    # NODE SERVICES
    litp inherit -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/services/sentinel -s /software/services/sentinel
done

SL_SG_pkg1=mysgroup4
SL_SG_pkg2=mysgroup5
# FAILOVER SERVICE GROUP

# APP SERVICE GROUP
litp create -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1" -t vcs-clustered-service -o active=1 standby=0 name=SL_vcs1 node_list='n3'
litp create -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/ha_configs/conf1 -t ha-service-config -o status_interval=100 status_timeout=60 restart_limit=6 startup_retry_limit=3
litp inherit -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/applications/luci -s /software/services/luci
litp create  -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_sl2_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg1"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_sl2_vip1_ipv6}" network_name=traffic3

# APP SERVICE GROUP
litp create -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg2" -t vcs-clustered-service -o active=1 standby=0 name=SL_vcs2 node_list='n4'
litp create -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg2"/ha_configs/conf1 -t ha-service-config -o status_interval=100 status_timeout=60 restart_limit=6 startup_retry_limit=3
litp inherit -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg2"/applications/luci -s /software/services/luci
litp create  -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg2"/ipaddresses/ip1 -t vip -o ipaddress="${nodes_sg_sl3_vip1}" network_name=traffic3
litp create  -p /deployments/d1/clusters/c1/services/"$SL_SG_pkg2"/ipaddresses/ip2 -t vip -o ipaddress="${nodes_sg_sl3_vip1_ipv6}" network_name=traffic3

########## VCS SERVICE GROUPS - CLUSTER SERVICES #############
# PEER NODE NETWORK
cluster=1
for (( i=0; i<${#node_expansion_sysname[@]}; i++ )); do

    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/if7 -t eth -o device_name=eth7 macaddress="${node_expansion_eth7_mac[$i]}"
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/br7 -t bridge -o device_name=br7 network_name=net1vm ipaddress="${net1vm_ip[$i+2]}"
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/network_interfaces/vlan911 -t vlan -o device_name=eth7.911 bridge=br7

    # FIREWALL FOR NODES
    litp create -p /deployments/d1/clusters/c$cluster/nodes/n$(($i+3))/configs/fw_config_init/rules/fw_vmhc -t firewall-rule -o name="300 vmhc" proto="tcp" dport=12987 provider=iptables
done

# VM PARALLEL SERVICE GROUP
litp create -p /software/images/image3 -t vm-image -o name="PL_SG_vm2" source_uri="http://${ms_ip}/images/vm_image_rhel6.qcow2"
litp create -p /software/services/vmservice3 -t vm-service -o service_name="CIvmserv3" image_name="PL_SG_vm2" cpus=4 ram=2000M internal_status_check=on cleanup_command="/sbin/service CIvmserv3 force-stop"
litp create -p /deployments/d1/clusters/c1/services/PL_SG_vm2 -t vcs-clustered-service -o name="PL_SG_vm2" active=2 standby=0 node_list='n2,n3' online_timeout=500
litp inherit -p /deployments/d1/clusters/c1/services/PL_SG_vm2/applications/vmservice3 -s /software/services/vmservice3
litp create -p /software/services/vmservice3/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br7 network_name=net1vm mac_prefix="52:53:54"
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm2/applications/vmservice3/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[3]},${vm_ip[4]}" gateway=${net1vm_gateway}
litp create -p /software/services/vmservice3/vm_aliases/cims -t vm-alias -o alias_names=cims address=${net1vm_ip_ms}
litp create -p /software/services/vmservice3/vm_aliases/cinode2 -t vm-alias -o alias_names=cinode2 address=${net1vm_ip[1]}
litp create -p /software/services/vmservice3/vm_aliases/cinode3 -t vm-alias -o alias_names=cinode3 address=${net1vm_ip[2]}
litp create -p /software/services/vmservice3/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_ip}/6/os/x86_64"
litp create -p /software/services/vmservice3/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages" # UPDATE
litp create -p /software/services/vmservice3/vm_packages/cups -t vm-package -o name=cups
litp create -p /software/services/vmservice3/vm_ssh_keys/sshkey1 -t vm-ssh-key -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpFjR8gr+9R4= key1@localhost.localdomain'	

# VM FAILOVER SERVICE GROUP
litp create -p /software/images/image4 -t vm-image -o name="FO_SG_vm2" source_uri="http://${ms_ip}/images/vm_image_rhel6.qcow2"
litp create -p /software/services/vmservice4 -t vm-service -o service_name="CIvmserv4" image_name="FO_SG_vm2" cpus=2 ram=4500M internal_status_check=on cleanup_command="/sbin/service CIvmserv4 force-stop"
litp create -p /deployments/d1/clusters/c1/services/FO_SG_vm2 -t vcs-clustered-service -o name="FO_SG_vm2" active=1 standby=1 node_list='n3,n1' online_timeout=500
litp inherit -p /deployments/d1/clusters/c1/services/FO_SG_vm2/applications/vmservice4 -s /software/services/vmservice4
litp create -p /software/services/vmservice4/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br7 network_name=net1vm
litp update -p /deployments/d1/clusters/c1/services/FO_SG_vm2/applications/vmservice4/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[5]}" gateway=${net1vm_gateway}
litp create -p /software/services/vmservice4/vm_aliases/cims -t vm-alias -o alias_names=cims address=${net1vm_ip_ms}
litp create -p /software/services/vmservice4/vm_aliases/cinode1 -t vm-alias -o alias_names=cinode1 address=${net1vm_ip[0]}
litp create -p /software/services/vmservice4/vm_aliases/cinode3 -t vm-alias -o alias_names=cinode3 address=${net1vm_ip[2]}
litp create -p /software/services/vmservice4/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_ip}/6/os/x86_64"
litp create -p /software/services/vmservice4/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages" # UPDATE
litp create -p /software/services/vmservice4/vm_packages/wireshark -t vm-package -o name=wireshark
litp create -p /software/services/vmservice4/vm_ssh_keys/sshkey1 -t vm-ssh-key -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtUpF2Mqgr+bE5= key2@localhost.localdomain'	

# VM PARALLEL SERVICE GROUP
litp create -p /software/images/image5 -t vm-image -o name="PL_SG_vm3" source_uri="http://${ms_ip}/images/vm_image_rhel6.qcow2"
litp create -p /software/services/vmservice5 -t vm-service -o service_name="CIvmserv5" image_name="PL_SG_vm3" cpus=4 ram=1900M internal_status_check=on cleanup_command="/sbin/service CIvmserv5 force-stop"
litp create -p /deployments/d1/clusters/c1/services/PL_SG_vm3 -t vcs-clustered-service -o name="PL_SG_vm3" active=3 standby=0 node_list='n1,n2,n3' online_timeout=600
litp inherit -p /deployments/d1/clusters/c1/services/PL_SG_vm3/applications/vmservice5 -s /software/services/vmservice5
litp create -p /software/services/vmservice5/vm_network_interfaces/vm_nic1 -t vm-network-interface -o device_name=eth0 host_device=br7 network_name=net1vm
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm3/applications/vmservice5/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[6]},${vm_ip[7]},${vm_ip[8]}" gateway=${net1vm_gateway}
litp create -p /software/services/vmservice5/vm_aliases/cims -t vm-alias -o alias_names=cims address=${net1vm_ip_ms}
litp create -p /software/services/vmservice5/vm_aliases/cinode1 -t vm-alias -o alias_names=cinode1 address=${net1vm_ip[0]}
litp create -p /software/services/vmservice5/vm_aliases/cinode2 -t vm-alias -o alias_names=cinode2 address=${net1vm_ip[1]}
litp create -p /software/services/vmservice5/vm_aliases/cinode3 -t vm-alias -o alias_names=cinode3 address=${net1vm_ip[2]}
litp create -p /software/services/vmservice5/vm_yum_repos/os -t vm-yum-repo -o name=os base_url="http://${ms_ip}/6/os/x86_64"
litp create -p /software/services/vmservice5/vm_yum_repos/updates -t vm-yum-repo -o name=rhelPatches base_url="http://${net1vm_ip_ms}/6/updates/x86_64/Packages" # UPDATE
litp create -p /software/services/vmservice5/vm_packages/cups -t vm-package -o name=cups
litp create -p /software/services/vmservice5/vm_ssh_keys/sshkey1 -t vm-ssh-key -o 'ssh_key=ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAxMEYvlt5OvXmPNyMP/QM/mAcDk0KpOgUg7PZNXz6jRU5d99a4cndSHIyoLYyP/4EuCVNUWsjCMFsm/B06zOlCxs6XNAId+bSiABF1Vr5XzjUiFRRqsV1hM7FrFBvImYYgKCLag5xwRhajJAdu/4J+ZgRmHOsHfeRJJoVWnVzjvDOSMSiYf+Lo8dYywy94tyNll4RnXKu4D6bqwSn9YEsJX03gzijwPDTdnMVGj+/+8NxwWbc6BzV0GX5QqY/FnZ6/yuC0jxjizYEaH56PIbkRmK2wNSewjEZDhFCAm0+JWJ1bPrmJXErP3X1KBKFZSpDyHPyLQNB280PwX0jXu+KVNXAbQQXx0sNi2+Qmrx3KnhJlKyJdw2W1qf5OdsL6arDduZB/aWR0xxVPvHHPh18lrhgJMm8dHgfNDTqISabpWQtdJOUbCssvLEOjeZoVlehnENWbI4+zfDNq/gwr3PJfzFOcWimwvZK8FlV1NfuzOgzMbmS1deQUb7wJ6YivlrIEHhElbjoXTfEw+eAhhTroJJ4YVIM/v2MoHe/aGBxsXl01xv7TZAWPppPPGJ+4R7qKKr4+XpkPSGJn1nBKd71cD4L4cSKy0Pqac+fw4Tt9kQ+SIwQYe8gbdXnvQdqpvTv/e+r5IA3QsRuktwV/tTCx++9ghXSJhtlS4jROf3+9R4= key1@localhost.localdomain'	

###############################################################
# UPDATE FROM INSTALL WITH EXPANSION
###############################################################

#UPDATE TO EXISTING SG's

litp create -p /deployments/d1/clusters/c1/services/mysgroup2/ha_configs/conf1 -t ha-service-config -o restart_limit=3 startup_retry_limit=4
litp update -p /deployments/d1/clusters/c1/services/mysgroup3/ha_configs/conf1 -o status_interval=180 status_timeout=60 restart_limit=12 startup_retry_limit=4 fault_on_monitor_timeouts=7 tolerance_limit=13 clean_timeout=70
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm1 -o online_timeout=450 offline_timeout=400 active=3 node_list='n1,n2,n3'
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm1/applications/vmservice1 -o hostnames=POnode1,POnode2,POnode3
litp update -p /deployments/d1/clusters/c1/services/PL_SG_vm1/applications/vmservice1/vm_network_interfaces/vm_nic1 -o ipaddresses="${vm_ip[0]},${vm_ip[1]},${vm_ip[9]}" ipv6addresses="${vm_ip6[0]},${vm_ip6[1]},${vm_ip6[9]}"
litp remove -p /deployments/d1/clusters/c1/network_hosts/nh16
litp remove -p /deployments/d1/clusters/c1/network_hosts/nh9

FO_SG_pkg=mysgroup1
PL_SG_pkg=mysgroup2
SL_SG_pkg=mysgroup3

# REMOVE DEPENDENCIES
litp update -p /deployments/d1/clusters/c1/services/"$FO_SG_pkg" -o dependency_list=$PL_SG_pkg
litp update -p /deployments/d1/clusters/c1/services/"$PL_SG_pkg" -o dependency_list=""

litp remove -p /deployments/d1/clusters/c1/services/FO_SG_vm1

# REMOVE A NIC INTERFANCE FROM A VM

litp remove -p /software/services/vmservice2/vm_network_interfaces/vm_nic2

###############################################################
# CREATE PLAN
###############################################################

litp create_plan
