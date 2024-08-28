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

# Configure TIPC interfaces
# https://confluence-oss.lmera.ericsson.se/display/LITP2UC/2.1+Configure+TIPC+interfaces
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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
echo "            send \"iptables -I INPUT 10 -p tcp -m state --state NEW -m tcp --dport 2049 -j ACCEPT;iptables-save > /etc/sysconfig/iptables; service iptables restart; mkdir -p /exports/cluster/etc; /bin/echo -e \'/exports/cluster ${node_hostname[0]}(rw,sync,no_root_squash)\n/exports/cluster ${node_hostname[1]}(rw,sync,no_root_squash)\' > /etc/exports; service nfs start; service nfs status; chkconfig nfs on; chkconfig --list | grep nfs; exportfs -a; exportfs; exit 0\n\"" >> /tmp/setupnfs.exp
echo "        }" >> /tmp/setupnfs.exp
echo "    }" >> /tmp/setupnfs.exp
echo "    set index [ expr \$index+1 ]" >> /tmp/setupnfs.exp
echo "}" >> /tmp/setupnfs.exp
echo "" >> /tmp/setupnfs.exp
echo "exit 0" >> /tmp/setupnfs.exp

expect /tmp/setupnfs.exp > $DIR/setupnfs_output.txt
mv /tmp/setupnfs.exp $DIR/setupnfs.exp
#rm -rf /tmp/setupnfs.exp

set -x

litpcrypt set key-for-root root 'Amm30n!!'
litp create -p /software/profiles/os_prof1 -t os-profile -o name=os-profile1 path=/var/www/html/6/os/x86_64/
litp create -p /deployments/d1 -t deployment
# 1 Cluster
litp create -t cmw-cluster -p /deployments/d1/clusters/c1 -o cluster_id=4766
litp create -p /ms/services/cobbler -t cobbler-service -o boot_network=mgmt
litp create -p /infrastructure/storage/storage_profiles/profile_1 -t storage-profile -o storage_profile_name=sp1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1 -t volume-group -o volume_group_name=vg_root1
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/root1 -t file-system -o type=ext4 mount_point=/ size=8G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/file_systems/swap1 -t file-system -o type=swap mount_point=swap size=2G
litp create -p /infrastructure/storage/storage_profiles/profile_1/volume_groups/vg1/physical_devices/internal -t physical-device -o device_name=hd0

litp create -p /infrastructure/systems/sys1 -t blade -o system_name="${ms_sysname}"
litp create -p /infrastructure/systems/sys1/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${ms_eth0_mac}"
litp create -p /infrastructure/systems/sys1/network_interfaces/nic_1 -t nic -o interface_name=eth1 macaddress="${ms_eth1_mac}"

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /infrastructure/systems/sys$(($i+2)) -t blade -o system_name="${node_sysname[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_0 -t nic -o interface_name=eth0 macaddress="${node_eth0_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_1 -t nic -o interface_name=eth1 macaddress="${node_eth1_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_2 -t nic -o interface_name=eth2 macaddress="${node_eth2_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/network_interfaces/nic_3 -t nic -o interface_name=eth3 macaddress="${node_eth3_mac[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/disks/disk0 -t disk -o name=hd0 size=28G bootable=true uuid="${node_disk_uuid[$i]}"
    litp create -p /infrastructure/systems/sys$(($i+2))/bmc -t bmc -o ipaddress="${node_bmc_ip[$i]}" username=root password_key=key-for-root
done

litp create -p /infrastructure/networking/ip_ranges/r1 -t ip-range -o network_name=mgmt start="${nodes_ip_start}" end="${nodes_ip_end}" subnet="${nodes_subnet}" #gateway="${nodes_gateway}"
litp create -p /infrastructure/networking/routes/route1 -t route -o name=default subnet="0.0.0.0/0" gateway="${nodes_gateway}"

# Network Profile 1 for MS
litp create -p /infrastructure/networking/network_profiles/np1 -t network-profile -o name=net-profile1 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np1/networks/mgmt -t network -o network_name=mgmt interface=nic0
litp create -p /infrastructure/networking/network_profiles/np1/interfaces/nic0 -t interface -o interface_basename=eth0
# Network Profile 2 for MNs
litp create -p /infrastructure/networking/network_profiles/np2 -t network-profile -o name=net-profile2 management_network=mgmt
litp create -p /infrastructure/networking/network_profiles/np2/networks/mgmt -t network -o network_name=mgmt interface=nic0 tipc_internal=true #default_gateway=true tipc_internal=true
litp create -p /infrastructure/networking/network_profiles/np2/interfaces/nic0 -t interface -o interface_basename=eth0
litp create -t network -p /infrastructure/networking/network_profiles/np2/networks/heartbeat1 -o interface=if2 network_name=heartbeat1
litp create -t interface -p /infrastructure/networking/network_profiles/np2/interfaces/if2 -o interface_basename=eth2

litp create -t network -p /infrastructure/networking/network_profiles/np2/networks/heartbeat2 -o interface=if3 network_name=heartbeat2
litp create -t interface -p /infrastructure/networking/network_profiles/np2/interfaces/if3 -o interface_basename=eth3

litp link -p /ms/system -t blade -o system_name="${ms_sysname}"
litp link -p /ms/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${ms_ip}"
litp link -p /ms/network_profile -t network-profile -o name=net-profile1
litp link -p /ms/routes/route1 -t route -o name=default
litp update -p /ms -o hostname=${ms_host}

for (( i=0; i<${#node_sysname[@]}; i++ )); do
    litp create -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -t node -o hostname="${node_hostname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/system -t blade -o system_name="${node_sysname[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/os -t os-profile -o name=os-profile1 
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/ipaddresses/ip1 -t ip-range -o network_name=mgmt address="${node_ip[$i]}"
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/network_profile -t network-profile -o name=net-profile2
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/storage_profile -t storage-profile -o storage_profile_name=sp1
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/items/ntp -t ntp-service 
    litp link -p /deployments/d1/clusters/c1/nodes/n$(($i+1))/routes/route1 -t route -o name=default
    litp update -p /deployments/d1/clusters/c1/nodes/n$(($i+1)) -o node_id=$[$i+1]
done

litp create 	-t ntp-service 	-p /software/items/ntp1 
litp link 	-t ntp-service 	-p /ms/items/ntp 
for (( i=0; i<${#ntp_ip[@]}; i++ )); do
    litp create 	-t ntp-server 	-p /software/items/ntp1/servers/server"$i" -o server="${ntp_ip[i+1]}"
done

litp create -t package -p /software/items/openjdk -o name=java-1.7.0-openjdk
litp link -p /ms/items/java -t package -o name=java-1.7.0-openjdk

litp link -t network -p /deployments/d1/clusters/c1/heartbeat_networks/hb1 -o network_name=heartbeat1
litp link -t network -p /deployments/d1/clusters/c1/heartbeat_networks/hb2 -o network_name=heartbeat2
litp link -p /deployments/d1/clusters/c1/mgmt_network -t network -o network_name=mgmt tipc_internal=true 
litp create_plan

