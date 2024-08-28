#!/bin/bash
#
# Sample LITP multi-blade deployment ('SAN' version)
#
# CMW - 2 nics for tipc
# 3 nics on MN
# 1 nics on MS
# 1 ntp server
# 1 network profile
# 
# component-name not set on cba-component
#
# WITH SMALL LUN - 26G
# /root size=16G snap_size=25
#
#
#
# Usage:
#   ST_Deployment_7.sh <CLUSTER_SPEC_FILE>
#

# Configure TIPC interfaces
# https://confluence-oss.lmera.ericsson.se/display/LITP2UC/2.1+Configure+TIPC+interfaces
echo "#!/usr/bin/expect" > /tmp/setupnfs.exp
echo "" >> /tmp/setupnfs.exp
echo "set timeout 120" >> /tmp/setupnfs.exp
echo "log_user 1" >> /tmp/setupnfs.exp
echo "" >> /tmp/setupnfs.exp
echo "spawn su - root" >> /tmp/setupnfs.exp
echo "" >> /tmp/setupnfs.exp
echo "set index 0;" >> /tmp/setupnfs.exp
echo "while { \$index < 3 } {" >> /tmp/setupnfs.exp
echo "    expect {" >> /tmp/setupnfs.exp
echo "        timeout {" >> /tmp/setupnfs.exp
echo "            send_user \"\n1\n\"" >> /tmp/setupnfs.exp
echo "            exit 1" >> /tmp/setupnfs.exp
echo "        }" >> /tmp/setupnfs.exp
echo "        \"Password: \" {" >> /tmp/setupnfs.exp
echo "            send \"@dm1nS3rv3r\n\"" >> /tmp/setupnfs.exp
echo "        }" >> /tmp/setupnfs.exp
echo "        \" ~]# \" {" >> /tmp/setupnfs.exp
echo "            send \"iptables -I INPUT 10 -p tcp -m state --state NEW -m tcp --dport 2049 -j ACCEPT;iptables-save > /etc/sysconfig/iptables; service iptables restart; mkdir -p /exports/cluster/etc; /bin/echo -e '/exports/cluster node\[0-9\](rw,sync,no_root_squash)' > /etc/exports; service nfs start; service nfs status; chkconfig nfs on; chkconfig --list | grep nfs; exportfs -a; exportfs; exit 0\n\"" >> /tmp/setupnfs.exp
echo "        }" >> /tmp/setupnfs.exp
echo "    }" >> /tmp/setupnfs.exp
echo "    set index [ expr \$index+1 ]" >> /tmp/setupnfs.exp
echo "}" >> /tmp/setupnfs.exp
echo "" >> /tmp/setupnfs.exp
echo "exit 0" >> /tmp/setupnfs.exp
expect /tmp/setupnfs.exp


if [ "$#" -lt 1 ]; then
    echo -e "Usage:\n  $0 <CLUSTER_SPEC_FILE>" >&2
    exit 1
fi

cluster_file="$1"
source "$cluster_file"

set -x

litpcrypt set key-for-root root "${nodes_ilo_password}"

litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment

#CMW
litp create -p /deployments/d1/clusters/c1 -t cmw-cluster -o cluster_id="${cluster_id}"

#LDE
litp create -p /software/items/lde -t cba-software
litp link -p /deployments/d1/clusters/c1/software/lde -t cba-software

#JAVA
litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk
litp link -p /ms/items/java -t package -o name=java-1.7.0-openjdk

litp create -p /ms/services/cobbler -t cobbler-service -o boot_network=mgmt
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root -t file-system -o type=ext4 mount_point=/ size=16G snap_size=25
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"
litp create -p /infrastructure/systems/sys1/network_interfaces/nic_1 -t nic -o interface_name=eth1 macaddress="${ms_eth1_mac}"

litp create -t ntp-service -p /software/items/ntp1 -o ensure='present'
litp create -t ntp-server -p /software/items/ntp1/servers/server0 -o server="${ntp_ip[0]}"

# managed nodes
for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${node_eth0_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=26G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root

    # tipc
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_2 -t nic -o interface_name=eth2 macaddress="${node_eth2_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_3 -t nic -o interface_name=eth3 macaddress="${node_eth3_mac[$i]}"
done

litp create -p /infrastructure/networking/ip_ranges/r1 -t ip-range -o network_name=mgmt start="${nodes_ip_start}" end="${nodes_ip_end}" subnet="${nodes_subnet}" gateway="${nodes_gateway}"

# network-profile 2 - used by managed nodes 
litp create -p /infrastructure/networking/network_profiles/np2 -t network-profile -o name=net-profile2 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np2/networks/mgmt -t network -o network_name=mgmt interface=nic0  default_gateway=true
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/nic0 -t interface -o interface_basename=eth0

litp create -p /infrastructure/networking/network_profiles/np2/networks/heartbeat1 -t network -o interface=if2 network_name=heartbeat1
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/if2 -t interface -o interface_basename=eth2
litp create -p /infrastructure/networking/network_profiles/np2/networks/heartbeat2 -t network -o interface=if3 network_name=heartbeat2
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/if3 -t interface -o interface_basename=eth3


litp link -p /ms/system -t blade -o system_name="${ms_sysname}"
litp link -p /ms/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${ms_ip}"

litp link -p /ms/items/ntp -t ntp-service -o ensure='present'
litp update -p /ms -o hostname="$ms_host"


for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -t blade -o system_name="${node_sysname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -t os-profile -o name=os-profile1 
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${node_ip[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_profile -t network-profile -o name=net-profile2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -t storage-profile -o storage_profile_name=sp1
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp1 -t ntp-service -o ensure='present'
    # node-id
    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$(($i+1))
done


litp link -t network -p /deployments/d1/clusters/c1/heartbeat_networks/hb1 -o network_name=heartbeat1
litp link -t network -p /deployments/d1/clusters/c1/heartbeat_networks/hb2 -o network_name=heartbeat2
litp link -p /deployments/d1/clusters/c1/mgmt_network -t network -o network_name=mgmt interface=nic0

litp create_plan
