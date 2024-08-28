#!/bin/bash

blade_type="G8"

ms_ilo_ip="10.44.84.46"
ms_ilo_username="root"
ms_ilo_password='Amm30n!!'
ms_ip="10.44.86.100"
ms_subnet="10.44.86.64/26"
ms_gateway="10.44.86.65"
ms_vlan=""
ms_vlan_id="835"
ms_host="ms1"
ms_eth0_mac="2C:59:E5:3D:D2:60"
ms_eth1_mac="2C:59:E5:3D:D2:64"
ms_eth2_mac="2C:59:E5:3D:D2:61"
#ms_ipv6_00="fdde:4d7e:d471::835:100:0/64"
ms_ipv6_00="fdde:4d7e:d471:0001:0:835:100:0/64"
ms_ipv6_00_noprefix="fdde:4d7e:d471:0001:0:835:100:0"
ms_disk_uuid="600508b1001cf359ce05eab77ddb5939"
#ipv6_gateway="fdde:4d7e:d471::835:0:1"
ipv6_gateway="fdde:4d7e:d471:0001:0:835:0:1"
ms_sysname="CZ32514HA9"

nodes_ip_start="10.44.86.100"
nodes_ip_end="10.44.86.102"
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

cluster_id="4800"

##SETUP VIPS
##Traffic network 3
##VCS requires gateway is pingable
traffic_network3_gw="172.16.201.2"
traffic_network3_gw_subnet="172.16.168.3/32"
traffic_network3_subnet="172.16.201.0/24"

fencing_disk1_uuid="6006016011602D0048DDF99FDC2DE411"
fencing_disk2_uuid="6006016011602D00C03757C5DC2DE411"
fencing_disk3_uuid="6006016011602D009025E8F3DC2DE411"

nodes_sg_fo1_vip1="172.16.201.8"
nodes_sg_fo1_vip2="172.16.201.9"
nodes_sg_pl1_vip1="172.16.201.10"
nodes_sg_pl1_vip2="172.16.201.11"
nodes_sg_sl1_vip1_ipv6="fdde:4d7e:d471:19::100:0/64"

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

##Setup nodes
node_ip[0]="10.44.86.101"
sanity_node_ip_check[0]="10.44.86.101"
node_ip_2[0]="$traffic_network1_gw"
node_ip_3[0]="$traffic_network2_gw"
node_ip_4[0]="$traffic_network3_gw"
node_sysname[0]="CZJ33308J0"
node_hostname[0]="node1"
node_eth0_mac[0]="2C:59:E5:3F:65:40"
node_eth1_mac[0]="2C:59:E5:3F:65:44"
#node_ipv6_00[0]="fdde:4d7e:d471::835:100:2/64"
node_ipv6_00[0]="fdde:4d7e:d471:0001:0:835:101:0/64"
node_ipv6_01[0]="fdde:4d7e:d471::835:100:3/64"
node_eth2_mac[0]="2C:59:E5:3F:65:41"
node_eth3_mac[0]="2C:59:E5:3F:65:45"
node_eth4_mac[0]="2C:59:E5:3F:65:42"
node_eth5_mac[0]="2C:59:E5:3F:65:46"
node_eth6_mac[0]="2C:59:E5:3F:65:43"
node_eth7_mac[0]="2C:59:E5:3F:65:47"
node_disk_uuid[0]="6006016011602d00a683b68c83cfe311"
node_disk1_uuid[0]="6006016011602d00c67269205980e411"
node_vxvm_uuid[0]="6006016011602D00248B5B630218E411"
node_vxvm2_uuid[0]="6006016011602D0032840FA8CF4FE411"
node_bmc_ip[0]="10.44.84.50"

node_ip[1]="10.44.86.102"
sanity_node_ip_check[1]="10.44.86.102"
node_ip_2[1]="172.16.100.3"
node_ip_3[1]="172.16.200.131"
node_ip_4[1]="172.16.201.3"
node_sysname[1]="CZJ33308J2"
node_hostname[1]="node2"
node_eth0_mac[1]="2C:59:E5:3D:B3:68"
node_eth1_mac[1]="2C:59:E5:3D:B3:6C"
#IPV6 addresses
#node_ipv6_00[1]="fdde:4d7e:d471::835:100:4/64"
node_ipv6_00[1]="fdde:4d7e:d471:0001:0:835:102:0/64"
node_ipv6_01[1]="fdde:4d7e:d471::835:100:5/64"
node_eth2_mac[1]="2C:59:E5:3D:B3:69"
node_eth3_mac[1]="2C:59:E5:3D:B3:6D"
node_eth4_mac[1]="2C:59:E5:3D:B3:6A"
node_eth5_mac[1]="2C:59:E5:3D:B3:6E"
node_eth6_mac[1]="2C:59:E5:3D:B3:6B"
node_eth7_mac[1]="2C:59:E5:3D:B3:6F"
node_disk_uuid[1]="6006016011602d0086a531a683cfe311"
node_disk1_uuid[1]="6006016011602d0040aabc435980e411"
node_vxvm_uuid[1]="6006016011602D00248B5B630218E411"
node_vxvm2_uuid[1]="6006016011602D0032840FA8CF4FE411"
node_bmc_ip[1]="10.44.84.51"

ntp_ip[1]="10.44.86.14"
ntp_ip[2]="127.127.1.0"

##NFS SETUP
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/CI/nfs_share_dir_100"
##SFS SETUP
#SFS
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_unmanaged_prefix="/vx/int_100-fs1"
sfs_prefix="/vx/CI100"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI100_cache1"
sfs_username="support"
sfs_password="support"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.86.231:master:master:/vx/CI100-managed-fs1=10.44.86.64/26:CI100-managed-fs1__BREAK__10.44.86.231:master:master:/vx/CI100-managed-fs2=10.44.86.101,/vx/CI100-managed-fs2=10.44.86.102:CI100-managed-fs2__BREAK__10.44.86.231:master:master:/vx/CI100-managed-fs3=10.44.86.64/26:CI100-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_CI100-managed-fs1_=CI100-managed-fs1:CI100_cache1"

######################### NEW VA SERVER ########################
##NFS SETUP
nfs_management_ip="10.44.86.14"
nfs_prefix="/home/admin/CI/nfs_share_dir_100"
##SFS SETUP
#SFS
sfs_management_ip="10.44.86.230"
sfs_vip="10.44.86.230"
sfs_unmanaged_prefix="/vx/int_100-fs1"
sfs_prefix="/vx/CI100"
sfs_pool1="ST_Pool"
sfs_pool2="ST_Pool2"
sfs_cache="CI100_cache1"
sfs_username="support"
sfs_password="veritas"
managedfs1="$sfs_prefix-managed-fs1"
managedfs2="$sfs_prefix-managed-fs2"
managedfs3="$sfs_prefix-managed-fs3"

sfs_cleanup_list="10.44.86.231:master:master:/vx/CI100-managed-fs1=10.44.86.64/26:CI100-managed-fs1__BREAK__10.44.86.231:master:master:/vx/CI100-managed-fs2=10.44.86.101,/vx/CI100-managed-fs2=10.44.86.102:CI100-managed-fs2__BREAK__10.44.86.231:master:master:/vx/CI100-managed-fs3=10.44.86.64/26:CI100-managed-fs3"

sfs_snapshot_cleanup_list="10.44.86.231:master:master:L_CI100-managed-fs1_=CI100-managed-fs1:CI100_cache1"

copytestfile1="http://10.44.235.150/cdb/image_with_ocf_v1_8.qcow2:/var/www/html/images/image_with_ocf_v1_8.qcow2"
copytestfile2="http://10.44.235.150/cdb/ci_test_service1-1.0-1.noarch.rpm:/tmp/test_services/ci_test_service1-1.0-1.noarch.rpm"
copytestfile3="http://10.44.235.150/cdb/vm_rhel_7_test_image-1-1.0.1.qcow2:/var/www/html/images/vm_rhel_7_test_image-1-1.0.1.qcow2"
copytestfile4="http://10.44.235.150/cdb/3PP-dutch-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-dutch-hello-1.0.0-1.noarch.rpm"
copytestfile5="http://10.44.235.150/cdb/3PP-english-hello-1.0.0-1.noarch.rpm:/tmp/test_services/3PP-english-hello-1.0.0-1.noarch.rpm"

net1vm_ip_ms="10.46.89.2"

net1vm_ip[0]="10.46.89.3"
net1vm_ip[1]="10.46.89.4"

net1vm_subnet="10.46.89.0/24"
net1vm_gateway="10.46.89.1"
net1vm_gateway6="fdde:4d7e:d471:46::89:1"
vm_ip[0]="10.46.89.5"
vm_ip[1]="10.46.89.6"
vm_ip[2]="10.46.89.7"
vm_ip_for_del[0]="10.46.89.23"
vm_ip_for_del[1]="10.46.89.24"
vm_ip6[0]="fdde:4d7e:d471:46::89:5/64"
vm_ip6[1]="fdde:4d7e:d471:46::89:6/64"
vm_ip6[2]="fdde:4d7e:d471:46::89:7/64"

ms_vm_ip[0]="10.46.89.8"
ms_vm_ip6[0]="fdde:4d7e:d471:46::89:8/64"
