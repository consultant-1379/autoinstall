#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.73"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.17"
ms_subnet="10.44.86.0/26"
ms_gateway="10.44.86.1"
ms_vlan=""
ms_host="ms1"
ms_eth0_mac="80:C1:6E:7A:79:68"
ms_eth1_mac="80:C1:6E:7A:79:6C"
ms_eth2_mac="80:C1:6E:7A:79:69"
ipv6_gateway="fdde:4d7e:d471::1"
ms_ipv6_00="fdde:4d7e:d471::834:17:0/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471::834:17:0"
ms_disk_uuid="600508b1001c6f1e1211fb97c40794eb"
ms_disk_uuid_sdb="600508b1001c6c3e2cee1063b20b7343"
ms_sysname="CZ3218HDW3"
cluster_id="4717"

nodes_ip_start="10.44.86.15"
nodes_ip_end="10.44.86.16"
nodes_subnet="$ms_subnet"
nodes_gateway="$ms_gateway"
nodes_ilo_password='Amm30n!!'
traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"

##VCS requires gateway is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"

nameserver_ip="10.44.86.14"

##network host settings
vcs_network_host1="172.16.101.10"
vcs_network_host3="2001:ABCD:F0::10"
vcs_network_host5="2001:ABCD:F0::10"
vcs_network_host6="172.16.101.11"
vcs_network_host7="2001:ABCD:F0::11"
vcs_network_host8="172.16.101.12"
vcs_network_host10="20.20.20.78"
vcs_network_host11="20.20.20.78"
vcs_network_host12="172.16.101.13"


##SETUP VIPS
##Traffic network 3
##VCS requires gateway is pingable
traffic_network3_gw="172.16.201.2"
traffic_network3_gw_subnet="172.16.168.3/32"
traffic_network3_subnet="172.16.201.0/24"

fencing_disk1_uuid="6006016011602d008e083746b1d0e511"
fencing_disk2_uuid="6006016011602d00c4868d68b1d0e511"
fencing_disk3_uuid="6006016011602d00200c498ab1d0e511"

nodes_sg_fo1_vip1="172.16.201.8"
nodes_sg_fo1_vip2="172.16.201.9"
nodes_sg_pl1_vip1="172.16.201.10"
nodes_sg_pl1_vip2="172.16.201.11"
nodes_sg_sl1_vip1="172.16.201.12"
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471::17:0/64"

# ##################################################### #
# ~~~~~~ NODE 1 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

node_hostname[0]="node1"
node_ip[0]="10.44.86.15"
node_bmc_ip[0]="10.44.84.74"
node_sysname[0]="CZ3218HDW5"

# IPV4 addresses
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"

# IPV6 addresses
node_ipv6_00[0]="fdde:4d7e:d471::834:14:2/64"
node_ipv6_01[0]="fdde:4d7e:d471::834:14:3/64"

# Node MAC addresses
node_eth0_mac[0]="80:C1:6E:7A:D9:90"
node_eth1_mac[0]="80:C1:6E:7A:D9:94"
node_eth2_mac[0]="80:C1:6E:7A:D9:91"
node_eth3_mac[0]="80:C1:6E:7A:D9:95"
node_eth4_mac[0]="80:C1:6E:7A:D9:92"
node_eth5_mac[0]="80:C1:6E:7A:D9:96"
node_eth6_mac[0]="80:C1:6E:7A:D9:93"
node_eth7_mac[0]="80:C1:6E:7A:D9:97"

# Node UUIDs
node_disk_uuid[0]="6006016011602d0058ee28aeb1d0e511"
node_disk1_uuid[0]="6006016011602d0066f369c8b1d0e511"
node_vxvm_uuid[0]="6006016011602d0086e14c0eb2d0e511"
node_vxvm2_uuid[0]="6006016011602d00487e6127b2d0e511"

# ##################################################### #
# ~~~~~~ NODE 2 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

node_hostname[1]="node2"
node_ip[1]="10.44.86.16"
node_bmc_ip[1]="10.44.84.72"
node_sysname[1]="CZ3218HDVW"

# IPV4 addresses
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"

# IPV6 addresses
node_ipv6_00[1]="fdde:4d7e:d471::834:14:4/64"
node_ipv6_01[1]="fdde:4d7e:d471::834:14:5/64"

# Node MAC addresses
node_eth0_mac[1]="80:C1:6E:7A:4B:F8"
node_eth1_mac[1]="80:C1:6E:7A:4B:FC"
node_eth2_mac[1]="80:C1:6E:7A:4B:F9"
node_eth3_mac[1]="80:C1:6E:7A:4B:FD"
node_eth4_mac[1]="80:C1:6E:7A:4B:FA"
node_eth5_mac[1]="80:C1:6E:7A:4B:FE"
node_eth6_mac[1]="80:C1:6E:7A:4B:FB"
node_eth7_mac[1]="80:C1:6E:7A:4B:FF"

# Node UUIDs
node_disk_uuid[1]="6006016011602d00d4f18edcb1d0e511"
node_disk1_uuid[1]="6006016011602d00ac64daf5b1d0e511"
node_vxvm_uuid[1]="6006016011602d0086e14c0eb2d0e511"
node_vxvm2_uuid[1]="6006016011602d00487e6127b2d0e511"

# ##################################################### #


ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"

# ~~~~~~ NFS Setup ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/SUP/nfs_share_dir_17"

# ~~~~~~ SFS Setup ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_unmanaged_prefix="/vx/int_17-fs1"
sfs_prefix="/vx/SUP17"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool"
sfs_cache="SUP17_cache1"
sfs_username="support"
sfs_password="support"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.86.231:master:master:/vx/SUP17-managed-fs1=10.44.86.0/26:SUP17-managed-fs1__BREAK__10.44.86.231:master:master:/vx/SUP17-managed-fs2=10.44.86.15,SUP17-managed-fs2=10.44.86.16:SUP17-managed-fs2__BREAK__10.44.86.231:master:master:/vx/SUP17-managed-fs3=10.44.86.0/26:SUP17-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_SUP17-managed-fs1_=SUP17-managed-fs1:SUP17_cache1"

# ##################################################### #

net1vm_ip_ms="10.46.95.2"

net1vm_ip[0]="10.46.95.3"
net1vm_ip[1]="10.46.95.4"
net1vm_ip[2]="10.46.95.5"
net1vm_ip[3]="10.46.95.6"

net1vm_subnet="10.46.95.0/24"
net1vm_gateway="10.46.95.1"
net1vm_gateway6="fdde:4d7e:d471:17::95:1"

vm_ip[0]="10.46.95.7"
vm_ip[1]="10.46.95.8"
vm_ip[2]="10.46.95.9"
vm_ip[3]="10.46.95.10"
vm_ip[4]="10.46.95.11"
vm_ip[5]="10.46.95.12"
vm_ip[6]="10.46.95.13"
vm_ip[7]="10.46.95.14"
vm_ip[8]="10.46.95.15"
vm_ip[9]="10.46.95.16"
vm_ip[10]="10.46.95.17"
vm_ip[11]="10.46.95.18"
vm_ip[12]="10.46.95.19"
vm_ip[13]="10.46.95.20"
vm_ip[14]="10.46.95.21"
vm_ip[15]="10.46.95.22"

vm_ip6[0]="fdde:4d7e:d471:17::95:7/64"
vm_ip6[1]="fdde:4d7e:d471:17::95:8/64"
vm_ip6[2]="fdde:4d7e:d471:17::95:9/64"
vm_ip6[3]="fdde:4d7e:d471:17::95:10/64"
vm_ip6[4]="fdde:4d7e:d471:17::95:11/64"
vm_ip6[5]="fdde:4d7e:d471:17::95:12/64"
vm_ip6[6]="fdde:4d7e:d471:17::95:13/64"
vm_ip6[7]="fdde:4d7e:d471:17::95:14/64"
vm_ip6[8]="fdde:4d7e:d471:17::95:15/64"
vm_ip6[9]="fdde:4d7e:d471:17::95:16/64"
vm_ip6[10]="fdde:4d7e:d471:17::95:17/64"
vm_ip6[11]="fdde:4d7e:d471:17::95:18/64"
vm_ip6[12]="fdde:4d7e:d471:17::95:19/64"
vm_ip6[13]="fdde:4d7e:d471:17::95:20/64"
vm_ip6[14]="fdde:4d7e:d471:17::95:21/64"
vm_ip6[15]="fdde:4d7e:d471:17::95:22/64"

ms_vm_ip[0]="10.46.95.30"
ms_vm_ip6[0]="fdde:4d7e:d471:17::95:30/64"

# ~~~~~~ Copy required files ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
copytestfile1="http://10.44.235.150/cdb/image_with_ocf-1.0.37.qcow2:/var/www/html/images/image_with_ocf_v1_8.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
