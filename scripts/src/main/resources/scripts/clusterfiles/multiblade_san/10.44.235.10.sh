#!/bin/bash

blade_type="DL380-G8"
ms_ilo_ip="10.44.84.26"
ms_ilo_username="root"
ms_ilo_password="Amm30n!!"
ms_ip="10.44.235.10"
ms_ip1="10.44.86.49"
ms_subnet="10.44.235.0/24"
ms_subnet1="10.44.86.0/26"
ms_gateway="10.44.235.1"
ms_host="ms1"
ms_eth0_mac="2C:44:FD:86:E3:D8"
ms_eth1_mac="2C:44:FD:86:E3:D9"
ms_eth2_mac="2C:44:FD:86:E3:DA"
ms_eth3_mac="2C:44:FD:86:E3:DB"
ms_eth4_mac="AC:16:2D:9C:7D:18"
ms_vlan="898"
#ms_ipv6_00="fdde:4d7e:d471::834:10:0/64"
ms_ipv6_00="fdde:4d7e:d471:0004:0:898:10:0/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471:0004:0:898:10:0"
ms_disk_uuid="600508b1001cabdaf2e3e27785c80367"
#ipv6_gateway="fdde:4d7e:d471::834:0:1"
ipv6_gateway="fdde:4d7e:d471:0004:0:898:0:1"

ms_sysname="CZ34164L0H"

nodes_subnet="$ms_subnet"
nodes_subnet2="10.44.86.0/26"
nodes_gateway="$ms_gateway"
nodes_gateway2="10.44.86.1"
second_network=true
nodes_ilo_password='Amm30n!!'


traffic_network1_gw_subnet="172.16.168.1/32"
traffic_network2_gw_subnet="172.16.168.2/32"

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
vcs_network_host13="172.16.101.14"
vcs_network_host14="172.16.101.15"

##VCS requires gateway is pingable
traffic_network1_gw="172.16.100.2"
traffic_network2_gw="172.16.200.130"

traffic_network1_subnet="172.16.100.0/24"
traffic_network2_subnet="172.16.200.128/24"

cluster_id="4810"

fencing_disk1_uuid="6006016020303300b48fd98a92bfe511"
fencing_disk2_uuid="6006016020303300e4ca38de92bfe511"
fencing_disk3_uuid="60060160203033009e67efb792bfe511"

##SETUP VIPS
##Traffic network 3
##VCS requires gateway is pingable
traffic_network3_gw="172.16.201.2"
traffic_network3_gw_subnet="172.16.168.3/32"
traffic_network3_subnet="172.16.201.0/24"

nodes_sg_fo1_vip1="172.16.201.8"
nodes_sg_fo1_vip2="172.16.201.9"
nodes_sg_pl1_vip1="172.16.201.10"
nodes_sg_pl1_vip2="172.16.201.11"
nodes_sg_sl1_vip1="172.16.201.12"
#nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471::19:42:12/64"
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:19::10:0/64"

node_ip[0]="10.44.235.11"
sanity_node_ip_check[0]="10.44.235.11"
node_ip_1[0]="10.44.86.45"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"
node_sysname[0]="CZ3450K22B"
node_hostname[0]="node1"
node_eth0_mac[0]="6C:C2:17:3D:64:E0"
node_eth1_mac[0]="6C:C2:17:3D:64:E8"
#node_ipv6_00[0]="fdde:4d7e:d471::834:15:2/64"
node_ipv6_00[0]="fdde:4d7e:d471:0004:0:898:11:0/64"
node_ipv6_01[0]="fdde:4d7e:d471::834:15:3/64"
node_eth2_mac[0]="6C:C2:17:3D:64:E1"
node_eth3_mac[0]="6C:C2:17:3D:64:E9"
node_eth4_mac[0]="6C:C2:17:3D:64:E2"
node_eth5_mac[0]="6C:C2:17:3D:64:EA"
node_eth6_mac[0]="6C:C2:17:3D:64:E3"
node_eth7_mac[0]="6C:C2:17:3D:64:EB"
#OLD SAN DISK UUIDS
#node_disk_uuid[0]="6006016011602d00fedf1215c897e311"
#node_disk1_uuid[0]="6006016011602d0082897480c897e311"
node_disk_uuid[0]="60060160203033008e57020b93bfe511"
#OLD SAN DISKS
node_disk1_uuid[0]="6006016020303300cc57572c93bfe511"
#node_disk1_uuid[0]="6006016011602D00448C83669380E411"

node_vxvm_uuid[0]="6006016020303300861dfe8793bfe511"
node_vxvm2_uuid[0]="6006016020303300c6277aa893bfe511"
node_bmc_ip[0]="10.44.84.106"

node_ip[1]="10.44.235.12"
sanity_node_ip_check[1]="10.44.235.12"
node_ip_1[1]="10.44.86.46"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"
node_sysname[1]="IEATRCXB4118"
node_hostname[1]="node2"
node_eth0_mac[1]="6C:C2:17:3D:61:30"
node_eth1_mac[1]="6C:C2:17:3D:61:38"
#IPV6 addresses
#node_ipv6_00[1]="fdde:4d7e:d471::834:15:4/64"
node_ipv6_00[1]="fdde:4d7e:d471:0004:0:898:12:0/64"
node_ipv6_01[1]="fdde:4d7e:d471::834:15:5/64"
node_eth2_mac[1]="6C:C2:17:3D:61:31"
node_eth3_mac[1]="6C:C2:17:3D:61:39"
node_eth4_mac[1]="6C:C2:17:3D:61:32"
node_eth5_mac[1]="6C:C2:17:3D:61:3A"
node_eth6_mac[1]="6C:C2:17:3D:61:33"
node_eth7_mac[1]="6C:C2:17:3D:61:3B"
#OLD SAN DISKS
#node_disk_uuid[1]="6006016011602d00fad8668ac897e311"
#node_disk1_uuid[1]="6006016011602d000429afecc897e311"
node_disk_uuid[1]="6006016020303300101cbf4893bfe511"
node_disk1_uuid[1]="60060160203033005aa4396093bfe511"
node_vxvm_uuid[1]="6006016020303300861dfe8793bfe511"
node_vxvm2_uuid[1]="6006016020303300c6277aa893bfe511"
node_bmc_ip[1]="10.44.84.109"

ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"

##NFS SETUP
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/CI/nfs_share_dir_10"
##SFS SETUP
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_unmanaged_prefix="/vx/int_10-fs1"
sfs_prefix="/vx/CI10"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI10_cache1"
sfs_username="support"
sfs_password="support"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.86.231:master:master:/vx/CI10-managed-fs1=10.44.235.0/24:CI10-managed-fs1__BREAK__10.44.86.231:master:master:/vx/CI10-managed-fs2=10.44.235.11,/vx/CI10-managed-fs2=10.44.235.12:CI10-managed-fs2__BREAK__10.44.86.231:master:master:/vx/CI10-managed-fs3=10.44.235.0/24:CI10-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_CI10-managed-fs1_=CI10-managed-fs1:CI10_cache1"

# VM IMAGE CONTENT
#vm_image_include="run_image"

copytestfile1="http://10.44.235.150/cdb/image_with_ocf_v1_8.qcow2:/var/www/html/images/image_with_ocf_v1_8.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/vm_rhel_7_test_image-1-1.0.1.qcow2:/var/www/html/images/vm_rhel_7_test_image-1-1.0.1.qcow2"
copytestfile4="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile5="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"

net1vm_ip_ms="10.46.91.2"

net1vm_ip[0]="10.46.91.3"
net1vm_ip[1]="10.46.91.4"

net1vm_subnet="10.46.91.0/24"
net1vm_gateway="10.46.91.1"
net1vm_gateway6="fdde:4d7e:d471:46::91:1"
vm_ip[0]="10.46.91.5"
vm_ip[1]="10.46.91.6"
vm_ip[2]="10.46.91.7"
vm_ip_for_del[0]="10.46.91.23"
vm_ip_for_del[1]="10.46.91.24"
vm_ip6[0]="fdde:4d7e:d471:46::91:5/64"
vm_ip6[1]="fdde:4d7e:d471:46::91:6/64"
vm_ip6[2]="fdde:4d7e:d471:46::91:7/64"

ms_vm_ip[0]="10.46.91.8"
ms_vm_ip6[0]="fdde:4d7e:d471:46::91:8/64"
